coffee  = require("coffee-script")
express = require("express")
spawn   = require("child_process").spawn

delay  = (ms, cb) -> setTimeout  cb, ms
every  = (ms, cb) -> setInterval cb, ms
escape = (arg)    -> '"' + arg.replace(/(["\|\s'$`\\])/g,'\\$1') + '"'

express.logger.format "method",     (req, res) -> req.method.toLowerCase()
express.logger.format "url",        (req, res) -> req.url.replace('"', "&quot")
express.logger.format "user-agent", (req, res) -> (req.headers["user-agent"] || "").replace('"', "")

app = express()

app.disable "x-powered-by"

app.use express.logger
  buffer: false
  format: "ns=\"swarm\" measure=\"http.:method\" source=\":url\" status=\":status\" elapsed=\":response-time\" from=\":remote-addr\" agent=\":user-agent\""
app.use express.cookieParser()
app.use express.bodyParser()
app.use app.router
app.use (err, req, res, next) -> res.send 500, error:(if err.message? then err.message else err)

app.get "/", (req, res) ->
  if req.query.input
    input = escape(req.query.input)
    expression = escape(req.query.expression)
    res.writeHead 200, "Content-Type":"application/json"
    jq = spawn("bash", ["-c", "curl -s \"#{input}\" | jq \"#{expression}\""])
    jq.stdout.on "data", (data) -> res.write data
    jq.stderr.on "data", (data) -> res.write data
    jq.on "exit",  -> res.end()
  else
    res.send """
      <div class="container" style="width:600px; margin-left: auto; margin-right: auto; margin-top: 100px;">
        <form method="get">
          <label for="input">Input (URL)</label>
          <input name="input" size="100" value="https://gist.github.com/raw/0f6d146cdfb814ab23d9/test.json">
          <br/><br/>
          <label for="express">Expression</label>
          <input name="expression" size="100" value=".[] | {name}">
          <br/><br/>
          <input type="submit" value="jq it">
        </form>
      </div>
    """

app.listen (process.env.PORT || 5000)
