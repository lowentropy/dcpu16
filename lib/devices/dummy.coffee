require.define ?= require('../require-define')(module, exports, __dirname, __filename)
require.define './devices/dummy', (require, module, exports, __dirname, __filename) ->

  module.exports = class DummyDevice

    name: 'DUMMY - Dummy Device'
    hardware_id: 0xdeadbeef
    version_id: 0x1337
    manufacturer_id: 0xf007ba11

    constructor: (@emu) ->

    send_interrupt: ->
      @emu.a.set 1
      @emu.b.set 2
      @emu.c.set 3
      @emu.x.set 4
      @emu.y.set 5
      @emu.z.set 6
      @emu.i.set 7
      @emu.j.set 8

    halt: ->
    pause: ->
    resume: ->
    reset: ->
