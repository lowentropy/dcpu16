tty = require 'tty'
express = require 'express'
programs = require './programs'

public = "#{__dirname}/../public"
compiled = "#{__dirname}/../compiled"
views = "#{__dirname}/../views"
styles = "#{__dirname}/../styles"

app = express.createServer()

io = require('socket.io').listen(app)

app.set 'views', views
app.set 'view engine', 'coffee'
app.set 'view options', layout: false
app.register '.coffee', require('coffeekup').adapters.express

app.use require('connect-assets')(build: true, minifyBuilds: false)

app.use express.bodyParser()
app.use express.methodOverride()
app.use express.static(public)
app.use express.static(compiled)

app.configure 'development', ->
  app.use express.errorHandler(dumpExceptions: true, showStack: true)

app.configure 'production', ->
  app.use express.errorHandler()

app.get '/', (req, res) ->
  res.render 'index', files: programs.files

app.listen 3000

programs.on_update (name, content) ->
  io.sockets.emit 'update_file', name, content

process.stdin.resume()
tty.setRawMode true
process.stdin.on 'keypress', (char, key) =>
  process.exit() if key?.ctrl && key.name == 'c'

console.log 'Server started on port 3000'