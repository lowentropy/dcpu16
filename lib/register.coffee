module.exports = class Register
  constructor: (@name) ->
    @value = 0
  
  get: ->
    @value
  
  set: (value) ->
    @value = value & 0xffff
