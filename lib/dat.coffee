require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './dat', (require, module, exports, __dirname, __filename) ->

  module.exports = class Dat
    constructor: (@line, @parts) ->
    
    extract_words: ->
      @words = []
      for part in @parts
        if /^".*"$/.test part
          @append_string eval(part)
        else if @line.program.has_label part
          @words.push @line.program.resolve_label(part)
        else
          @words.push parseInt(part)

    append_string: (str) ->
      for i in [0...str.length]
        @words.push str.charCodeAt(i)
  
    extract_size: ->
      @_size = 0
      for part in @parts
        if /^".*"$/.test part
          @_size += eval(part).length
        else
          @_size++
  
    size: ->
      @extract_size() unless @_size?
      @_size
  
    to_bin: ->
      @extract_words() unless @words?
      @words

    is_op: ->
      false