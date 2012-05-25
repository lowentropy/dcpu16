require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './operand', (require, module, exports, __dirname, __filename) ->

  module.exports = class Operand
    constructor: (@emu, @pos) ->
      @word_loc =
        get: => @word
        set: ->
      @literal_loc =
        get: => (@code - 0x21) & 0xffff
        set: ->
  
    reset: (@code) ->
      @get_word()
      @_loc = null
      @cached = null
  
    get: ->
      @cached ?= @loc().get()
  
    set: (value) ->
      @loc().set(value)
  
    get_word: ->
      if @needs_word()
        @word = @emu.get_word()
  
    needs_word: ->
      (0x10 <= @code < 0x18) ||
      (@code == 0x1a) ||
      (@code == 0x1e) ||
      (@code == 0x1f)
  
    loc: ->
      @_loc ?= if @code < 0x08
        @emu.registers[@code]
      else if @code < 0x10
        @emu.mem @emu.registers[@code - 0x08].get()
      else if @code < 0x18
        addr = @word + @emu.registers[@code - 0x10].get()
        @emu.mem addr
      else if @code == 0x18
        @emu.cycles 1
        if @pos == 'a'
          addr = @emu.sp.get()
          @emu.sp.set @emu.sp.get() + 1
          @emu.mem addr
        else
          addr = @emu.sp.get() - 1
          @emu.sp.set addr
          @emu.mem addr
      else if @code == 0x19
        @emu.mem @emu.sp.get()
      else if @code == 0x1a
        @emu.cycles 1
        @emu.mem(@emu.sp.get() + @word)
      else if @code == 0x1b
        @emu.sp
      else if @code == 0x1c
        @emu.pc
      else if @code == 0x1d
        @emu.ex
      else if @code == 0x1e
        @emu.cycles 1
        @emu.mem @word
      else if @code == 0x1f
        @emu.cycles 1
        @word_loc
      else
        @literal_loc
