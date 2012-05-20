express = require 'express'
stylus = require 'stylus'
browserify = require 'browserify'

public = "#{__dirname}/../public"
compiled = "#{__dirname}/../compiled"
views = "#{__dirname}/../views"
styles = "#{__dirname}/../styles"

app = express.createServer()
bundle = browserify()

app.use bundle

app.set 'views', views
app.set 'view engine', 'coffee'
app.set 'view options', layout: false
app.register '.coffee', require('coffeekup').adapters.express

app.use express.bodyParser()
app.use express.methodOverride()
app.use stylus.middleware(src: styles, dest: compiled)
app.use express.static(public)
app.use express.static(compiled)

app.configure 'development', ->
  app.use express.errorHandler(dumpExceptions: true, showStack: true)

app.configure 'production', ->
  app.use express.errorHandler()

bundle.addEntry "#{__dirname}/../client/index.coffee"

app.get '/', (req, res) ->
  res.render 'index'

app.listen 3000

console.log 'Server started on port 3000'