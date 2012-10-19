require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './line', (require, module, exports, __dirname, __filename) ->

  Noop = require './noop'
  Dat = require './dat'
  Operation = require './operation'

  module.exports = class Line
    constructor: (@program, @raw, @file, @lineno) ->
      @labels = []
      @str = @raw
      @pre_parse()

    pre_parse: ->
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
      parts = []
      while (@str = @str.trim()).length
        if @str[0] == '"'
          parts.push @read_string()
        else
          if m = @str.match /^([^\s,]+)/
            parts.push m[1]
            @str = @str.substring(m[0].length)
          else
            throw new Error "Can't match: #{@str}"
        @chomp()
      @op = parts.shift()
      @parts = parts

    chomp: ->
      if m = @str.match /^[\s,]+/
        @str = @str.substring m[0].length

    read_string: ->
      idx = 1
      escape = false
      while idx < @str.length
        ch = @str[idx]
        break if !escape && (ch == '"')
        escape = !escape && (ch == '\\')
        idx++
      str = @str.substring(0, idx + 1)
      @str = @str.substring(idx + 1)
      str

    empty: ->
      !@op?

    parse: ->
      @contents = if @empty()
        new Noop
      else if /dat/i.test @op
        new Dat this, @parts
      else if /require/i.test @op
        new Noop
      else
        new Operation this, @op, @parts

    set_addr: (@addr) ->

    is_op: -> @contents.is_op()
    to_bin: -> @contents.to_bin()
    size: -> @contents.size()

  class EmptyLine extends Line
    constructor: (@program, @file, @lineno) ->
      super @program, '', @file, @lineno
    empty: -> true
    is_op: -> false
    to_bin: -> []
    size: -> 0
    parse: ->
    set_addr: (@addr) ->

  Line.empty = (args...) ->
    new EmptyLine args...
