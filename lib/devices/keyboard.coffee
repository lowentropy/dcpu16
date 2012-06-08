require.define ?= require('../require-define')(module, exports, __dirname, __filename)
require.define './devices/keyboard', (require, module, exports, __dirname, __filename) ->

  tty = require 'tty'

  module.exports = class TTYKeyboard
    constructor: (@emu) ->
      @buffer = []
  
    name: 'Generic Keyboard (compatible)'
    hardware_id: 0x30cf7406
    version_id: 1
    manufacturer_id: 0
  
    send_interrupt: ->
      switch @emu.a.get()
        when 0 then @clear_buffer()
        when 1 then @next_key()
        when 2 then @check_state()
        when 3 then @set_message()
  
    clear_buffer: ->
      @buffer = []
  
    set_message: ->
      @message = @emu.b.get()
  
    next_key: ->
      if @buffer.length
        @emu.c.set @buffer.shift()
      else
        @emu.c.set 0
  
    check_state: ->
      key = @emu.b.get()
      value = if @is_pressed(key) then 1 else 0
      @emu.c.set value
  
    is_pressed: (key) ->
      # XXX can't do this on a TTY with node :(
      false
  
    event: ->
      @emu.trigger_interrupt @message if @message
  
    push: (code) ->
      @buffer.push code
      @event()
  
    process: (key, char) ->
      if char
        code = char.charCodeAt(0)
        if 0x20 <= code <= 0x7f
          @push code
          return
      if key
        code = switch key.name
          when 'backspace' then 0x10
          when 'enter' then 0x11
          when 'return' then 0x11
          when 'insert' then 0x12
          when 'delete' then 0x13
          when 'up' then 0x80
          when 'down' then 0x81
          when 'left' then 0x82
          when 'right' then 0x83
        @push code if code
  
    start: ->
      @active = true
      process.stdin.on 'keypress', (char, key) =>
        @process key, char if @active

    halt: ->
      @active = false

    pause: ->
      @halt()
    
    resume: ->
      @active = true