consts = require './consts'
ops = require './ops'

module.exports = class Emulator
  constructor: ->
    for reg in 'a b c x y z i j ia sp pc ex'.split(' ')
      @[reg] = new Register reg
    @registers = [@a, @b, @c, @x, @y, @z, @i, @j]
    @mem = (0 for i in [0x0000..0xffff])
    @devices = []
    ops.init this
    @max_steps = 100000
    @real_time = false
    @iq_enabled = false
  
  load_program: (program) ->
    @mem[i] = word for word, i in program.to_bin()
    
  cycles: (n) ->
    @_cycles += n
  
  send_interrupt: (hw_idx) ->
    @devices[hw_idx]?.send_interrupt()
  
  attach_device: (device) ->
    @devices.push device
  
  trigger_interrupt: (message) ->
    if 0 != (ia = @ia.get())
      @enable_iq()
      @push @pc.get()
      @push @a.get()
      @pc.set ia
      @a.set message
    
  get_device_info: (hw_idx) ->
    if device = @devices[hw_idx]
      @a.set device.hardware_id
      @b.set device.hardware_id >> 16
      @c.set device.version_id
      @x.set device.manufacturer_id
      @y.set device.manufacturer_id >> 16
  
  num_devices: ->
    @devices.length
  
  push: (value) ->
    @sp.set(addr = @sp.get() - 1)
    @mem_set addr, value
  
  mem_set: (addr, value) ->
    @mem[addr & 0xffff] = value & 0xffff
  
  mem_get: (addr) ->
    @mem[addr & 0xffff]
  
  mem: (addr) ->
    get: => @mem_get(addr)
    set: (value) => @mem_set(addr, value)
  
  pop: ->
    value = @mem_get @sp.get()
    @sp.set @sp.get() + 1
    value
  
  skip: ->
    @_skip = true
    @cycles 1
    @advance()
    @read_args()
    @skip() if @instruction_is_if()

  advance: ->
    @inst = @get_word()

  get_word: ->
    word = @mem_get @pc.get()
    @pc.set @pc.get() + 1
    word

  instruction_is_if: ->
    0x10 <= (@inst & 0x1f) < 0x18

  enable_iq: ->
    @iq_enabled = true
  
  disable_iq: ->
    @iq_enabled = false
  
  step: ->
    @_cycles = 0
    @advance()
    return @halt() unless @inst
    @read_args()
    @perform()
    @steps++
    @halt() if @steps > @max_steps
    @pause() if @real_time
  
  pause: ->
    # TODO: wait for correct ms...
  
  halt: ->
    @_halt = true
  
  clear: ->
    @steps = 0
  
  run: ->
    @clear()
    @step() until @_halt
  
  dump: ->
    for value, addr in @mem
      continue unless value
      console.log "#{addr}: #{value}"
  
  read_args: ->
    @_a = new Operand this, (@inst >> 10) & 0x3f, 'a'
    if (@inst & 0x1f) != 0
      @_b = new Operand this, (@inst >> 5) & 0x1f, 'b'

  perform: ->
    op = @inst & 0x1f
    if op == 0
      fun = consts.extended[(@inst >> 5) & 0x1f].toLowerCase()
      ops[fun]?(@_a)
    else
      fun = consts.basic[op].toLowerCase()
      ops[fun]?(@_b, @_a)


class Operand
  constructor: (@emu, @code, @pos) ->
    @loc()
    @get() if @pos == 'a'
  
  get: ->
    @cached ?= @loc().get()
  
  set: (value) ->
    @loc().set(value)
  
  loc: ->
    @_loc ?= if @code < 0x08
      @emu.registers[@code]
    else if @code < 0x10
      @emu.mem @emu.registers[@code - 0x08].get()
    else if @code < 0x18
      word = @emu.get_word()
      addr = word + @emu.registers[@code - 0x10].get()
      @emu.mem addr
    else if @code == 0x18
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
      offset = @emu.get_word()
      @emu.mem(@emu.sp.get() + offset)
    else if @code == 0x1b
      @emu.sp
    else if @code == 0x1c
      @emu.pc
    else if @code == 0x1d
      @emu.ex
    else if @code == 0x1e
      word = @emu.get_word()
      @emu.mem word
    else if @code == 0x1f
      word = @emu.get_word()
      get: -> word
      set: ->
    else
      get: => (@code - 0x21) & 0xffff
      set: ->


class Register
  constructor: (@name) ->
    @value = 0
  
  get: ->
    @value
  
  set: (value) ->
    @value = value & 0xffff
