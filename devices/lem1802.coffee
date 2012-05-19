module.exports = class LEM1802
  constructor: (@emu) ->

  name: 'LEM1802 - Low Energy Monitor'
  hardware_id: 0x7349f615
  version_id: 0x1802
  manufacturer_id: 0x1c6c8b36
  
  send_interrupt: ->
    # TODO