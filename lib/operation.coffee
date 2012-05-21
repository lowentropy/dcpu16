require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './operation', (require, module, exports, __dirname, __filename) ->

  consts = require './consts'
  Value = require './value'

  module.exports = class Operation
    constructor: (@line, op, parts) ->
      @op = op.toUpperCase()
      @a = new Value this, parts.pop(), 'a'
      @b = new Value this, parts.pop(), 'b' if parts.length
    
    assemble: ->
      @word = @a.to_bin() << 10
      if @extended()
        @word |= (@extended_opcode() << 5)
      else
        @word |= (@b.to_bin() << 5)
        @word |= @basic_opcode()
      @_words = [@word]
      @_words.push @a.next_word() if @a.next
      @_words.push @b.next_word() if @b?.next
  
    extended: ->
      @_extended ?= (consts.extended.indexOf(@op) >= 0)
  
    basic_opcode: ->
      consts.basic.indexOf @op
  
    extended_opcode: ->
      consts.extended.indexOf @op
  
    words: ->
      @assemble() unless @_words
      @_words
  
    size: ->
      1 + (if @a.next then 1 else 0) + (if @b?.next then 1 else 0)
  
    to_bin: ->
      @words()
