require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './devices/clock', (require, module, exports, __dirname, __filename) ->

  module.exports = class GenericClock
    constructor: (@emu) ->
      @elapsed = 0
      @msg = null
      @callbacks = []

    name: 'Generic Clock (compatible)'
    hardware_id: 0x12d0b402
    version_id: 1
    manufacturer_id: 0
  
    send_interrupt: ->
      console.log "CLICK INTERRUPT" # XXX
      switch @emu.a.get()
        when 0 then @tick_at @emu.b.get() * 1000 / 60
        when 1 then @emu.c.set @get_elapsed()
        when 2 then @msg = @emu.b.get()

    tick_at: (@ms) ->
      clearInterval @interval if @interval
      @interval = setInterval (=> @tick()), @ms if @ms
      console.log "SET INTERVAL: #{@interval}" # XXX
  
    tick: ->
      @elapsed++
      @emu.trigger_interrupt @msg if @msg
      callback() for callback in @callbacks
  
    get_elapsed: ->
      el = @elapsed
      @elapsed = 0
      el
    
    on_tick: (callback) ->
      @callbacks.push callback

    halt: ->
      console.log "CLOCK HALT: #{@interval}" # XXX
      clearInterval @interval if @interval
    
    pause: ->
      @halt()
    
    resume: ->
      console.log 'CLOCK RESUME' # XXX
      @tick_at @ms if @ms