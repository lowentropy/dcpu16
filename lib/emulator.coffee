require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './emulator', (require, module, exports, __dirname, __filename) ->

  consts = require './consts'
  ops = require './ops'
  Register = require './register'
  Operand = require './operand'

  reg_names = 'a b c x y z i j ia sp pc ex'.split(' ')

  module.exports = class Emulator

    constructor: (opts={}) ->
      { @real_time, @max_queue_length, @chunk_size, @debounce_timeout } = opts
      @max_queue_length ?= 256
      @chunk_size ?= 100
      @debounce_timeout ?= 100
      ops.init this
      @devices = []
      @_mem_hooks = {}
      @all_registers = for reg in reg_names
        @[reg] = new Register reg
      @registers = [@a, @b, @c, @x, @y, @z, @i, @j]
      @fire_callback = @default_fire_callback
      @reset()

    reset: ->
      @halt()
      device.reset() for device in @devices
      reg.set 0 for reg in @all_registers
      @_mem = (0 for i in [0x0000..0xffff])
      @_halt = false
      @_on_fire = false
      @iq_enabled = false
      @total_cycles = 0
      @_a = new Operand this, 'a'
      @_b = new Operand this, 'b'
      @_next_trigger = 1
      @mem_triggers = {}
      @debounce_timers = {}
      @queue = []
      @_chunk = 0
      @call_back()

    load_program: (@program, clear_breakpoints=true) ->
      @breakpoints = {} if clear_breakpoints
      @_mem[i] = word for word, i in @program.to_bin()
      @program

    _line: ->
      @program?.line_map?[@pc.get()]

    line: ->
      @_line()?.lineno

    set_breakpoint: (addr, enabled=true) ->
      @breakpoints[addr] = enabled

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
      else if ia = @ia.get()
        @enable_iq()
        @push @pc.get()
        @push @a.get()
        @pc.set ia
        @a.set message

    queue_interrupt: (message) ->
      if @queue.length >= @max_queue_length
        @catch_fire()
      else
        @queue.push message

    catch_fire: ->
      @fire_callback() unless @_on_fire
      @_on_fire = true
      @halt()

    default_fire_callback: ->
      console.log ">>> DCPU ON FIRE! <<<"

    pause: ->
      @_halt = true
      @_paused = true
      device.pause() for device in @devices
      null

    resume: ->
      if @_paused
        device.resume() for device in @devices
      @_paused = false

    on_fire: (@fire_callback) ->

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

    debounce: (key, callback) ->
      clearTimeout @debounce_timers[key]
      @debounce_timers[key] = setTimeout @debounce_timeout, callback

    mem_set: (addr, value) ->
      addr &= 0xffff
      value &= 0xffff
      @_mem[addr] = value
      for key, {from, to, callback} of @mem_triggers
        continue unless from <= addr < to
        @debounce key, -> callback(addr, value)
      null

    mem_get: (addr) ->
      @_mem[addr & 0xffff]

    mem: (addr) ->
      @_mem_hooks[addr] ?= {
        set: (value) => @mem_set(addr, value)
        get: => @mem_get(addr)}

    pop: ->
      value = @mem_get(addr = @sp.get())
      @sp.set addr + 1
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
      word = @mem_get(pc = @pc.get())
      @pc.set(pc + 1)
      word

    instruction_is_if: ->
      0x10 <= (@inst & 0x1f) < 0x18

    enable_iq: ->
      @iq_enabled = true

    disable_iq: ->
      @iq_enabled = false

    _step: ->
      @_cycles = 0
      if @stop_on_breakpoint()
        @_halt = true
      else if !@advance()
        @halt()
        @_done_callback() if @_done_callback
      else
        @read_args()
        @perform()
        @check_queue()

    step: ->
      @resume()
      @_step()
      @call_back()

    check_queue: ->
      if @queue.length && !@iq_enabled && !@recent_rfi
        @trigger_interrupt @queue.shift()
      @recent_rfi = false

    stop_on_breakpoint: ->
      addr = @pc.get()
      skip = @skip_next_bp
      @skip_next_bp = false
      if !skip && @breakpoints[addr]
        @_breakpoint_callback() if @_breakpoint_callback
        true
      else
        false

    call_back: ->
      reg.call_back() for reg in @all_registers
      @_cycles_callback @total_cycles if @_cycles_callback

    on_cycles: (@_cycles_callback) ->
    on_breakpoint: (@_breakpoint_callback) ->

    next_is_jsr: ->
      (@mem[@pc.get()] & 0x3ff) == 0x20

    halt: ->
      @_halt = true
      device.halt() for device in @devices

    run: ->
      @resume()
      @skip_next_bp = true
      @_halt = false
      @_run()

    _run: ->
      while !@_halt
        @_step()
        if @_chunk++ >= @chunk_size
          @_chunk = 0
          process.nextTick (=> @_run())
          break
      @call_back()

    on_done: (@_done_callback) ->

    dump: ->
      for value, addr in @_mem
        continue unless value
        console.log "#{addr}: #{value}"

    read_args: ->
      @_a.reset (@inst >> 10) & 0x3f
      if (@inst & 0x1f) != 0
        @_b.reset (@inst >> 5) & 0x1f

    perform: ->
      @_a.get()
      if op = @inst & 0x1f
        ops.basic[op](@_b, @_a)
      else if ext = (@inst >> 5) & 0x1f
        ops.extended[ext](@_a)

    error: (msg) ->
      throw new Error "#{msg} (line #{@line()})"

    mem_trigger: (from, to, callback) ->
      key = @_next_trigger++
      @mem_triggers[key] = {from, to, callback}
      key

    remove_mem_trigger: (key) ->
      delete @mem_triggers[key]

