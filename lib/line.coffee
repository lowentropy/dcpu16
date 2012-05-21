require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './line', (require, module, exports, __dirname, __filename) ->

  Noop = require './noop'
  Dat = require './dat'
  Operation = require './operation'

  module.exports = class Line
    constructor: (@program, @raw, @lineno) ->
      @labels = []
      @str = @raw
      @remove_comments()
      @parse_labels()
      @split()
  
    remove_comments: ->
      if -1 < (idx = @str.indexOf ';')
        @comment = @str.substring idx+1
        @str = @str.substring 0, idx
  
    parse_labels: ->
      re = /^\s*:(\w+)/
      while m = re.exec(@str)
        [text, label] = m
        @str = @str.substring text.length
        @labels.push label

    split: ->
      if (@str = @str.trim()).length
        m = @str.match /^([^\s]+)\s+(.*)$/
        @op = m[1]
        @parts = m[2].split(/,\s*/)
  
    empty: ->
      !@op?
  
    parse: ->
      @contents = if @empty()
        new Noop
      else if /dat/i.test @op
        new Dat this, @parts
      else
        new Operation this, @op, @parts
  
    set_addr: (@addr) ->
  
    to_bin: -> @contents.to_bin()
    size: -> @contents.size()
