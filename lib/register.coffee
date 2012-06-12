require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './register', (require, module, exports, __dirname, __filename) ->

  module.exports = class Register
    constructor: (@name) ->
      @value = 0
  
    get: ->
      @value
  
    set: (value) ->
      @value = value & 0xffff
      @_dirty = true
    
    call_back: ->
      if @_dirty
        @_dirty = false
        @callback(@value) if @callback

    on_set: (@callback) ->
