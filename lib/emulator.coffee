consts = require './consts'
ops = require './ops'

module.exports = class Emulator
  constructor: (opts={}) ->
    {@sync} = opts
    for reg in 'a b c x y z i j ia sp pc ex'.split(' ')
      @[reg] = new Register reg
    @registers = [@a, @b, @c, @x, @y, @z, @i, @j]
    @_mem = (0 for i in [0x0000..0xffff])
    @devices = []
    ops.init this
    # @max_steps = 100000
    @real_time = false
    @iq_enabled = false
    @total_cycles = 0
    @queue = []
  
  load_program: (program) ->
    @_mem[i] = word for word, i in program.to_bin()
    
  cycles: (n) ->
    @_cycles += n
    @total_cycles += n
  
  send_interrupt: (hw_idx) ->
    @devices[hw_idx]?.send_interrupt()
  
  attach_device: (device) ->
    @devices.push device
  
  trigger_interrupt: (message) ->
    if @iq_enabled
      @queue_interrupt message
      return
    if 0 != (ia = @ia.get())
      @enable_iq()
      @push @pc.get()
      @push @a.get()
      @pc.set ia
      @a.set message
  
  queue_interrupt: (message) ->
    if @queue.length >= 256
      @catch_fire()
    @queue.push message

  catch_fire: ->
    console.log ">>> DCPU ON FIRE! <<<" unless @on_fire
    @on_fire = true
    @halt()
    
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
    @_mem[addr & 0xffff] = value & 0xffff
  
  mem_get: (addr) ->
    @_mem[addr & 0xffff]
  
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
    # FIXME: there's a bug here; we want to read the args but NOT to evaluate things like POP...
    # TODO: express this bug in a test, then fix it...
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
    return @halt() if @total_steps > @max_steps
    if @queue.length && !@iq_enabled && !@recent_rfi
      @trigger_interrupt @queue.shift()
    @recent_rfi = false
    setTimeout (=> @step()), @pause() unless @_halt || @sync
  
  pause: ->
    0
    # TODO: wait for correct ms...
  
  halt: ->
    @_halt = true
    device.halt() for device in @devices
    @callback?()
  
  clear: ->
    @steps = 0
  
  run: (@callback) ->
    @clear()
    if @sync
      @step() until @_halt
    else
      @step()
  
  dump: ->
    for value, addr in @_mem
      continue unless value
      console.log "#{addr}: #{value}"
  
  read_args: ->
    @_a = new Operand this, (@inst >> 10) & 0x3f, 'a'
    if (@inst & 0x1f) != 0
      @_b = new Operand this, (@inst >> 5) & 0x1f, 'b'

  perform: ->
    op = @inst & 0x1f
    @_a.get()
    if op == 0
      fun = consts.extended[(@inst >> 5) & 0x1f].toLowerCase()
      ops[fun]?(@_a)
    else
      fun = consts.basic[op].toLowerCase()
      ops[fun]?(@_b, @_a)


class Operand
  constructor: (@emu, @code, @pos) ->
    # @loc()
    @get_word()
  
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
      get: => @word
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