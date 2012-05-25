require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './emulator', (require, module, exports, __dirname, __filename) ->

  consts = require './consts'
  ops = require './ops'
  Register = require './register'
  Operand = require './operand'


  module.exports = class Emulator
    constructor: (opts={}) ->
      {@sync, @real_time, @max_queue_length} = opts
      @max_queue_length ?= 256
      ops.init this
      @devices = []
      for reg in 'a b c x y z i j ia sp pc ex'.split(' ')
        @[reg] = new Register reg
      @registers = [@a, @b, @c, @x, @y, @z, @i, @j]
      @all_registers = @registers.concat [@pc, @sp, @ex, @ia]
      @_cycles_callback = ->
      @reset()
      
    reset: ->
      reg.set 0 for reg in @registers
      @pc.set 0; @sp.set 0; @ex.set 0
      @_mem = (0 for i in [0x0000..0xffff])
      @_halt = false    
      @_on_fire = false  
      @iq_enabled = false
      @total_cycles = 0
      @_a = new Operand this, 'a'
      @_b = new Operand this, 'b'
      @_next_trigger = 1
      @mem_triggers = {}
      @queue = []
      @load_program(@program) if @program
      @callback = ->
      @_chunk = 0
      @_nul = ->
  
    load_program: (@program) ->
      @_mem[i] = word for word, i in @program.to_bin()
    
    line: ->
      @program.line_map[@pc.get()]?.lineno
    
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
      if @queue.length >= @max_queue_length
        return @catch_fire()
      @queue.push message

    catch_fire: ->
      unless @_on_fire
        if @fire_callback
          @fire_callback()
        else
          console.log ">>> DCPU ON FIRE! <<<"
      @_on_fire = true
      @halt()
    
    pause: ->
      @_halt = true
      @_paused = true
      device.pause() for device in @devices
    
    resume: ->
      @_halt = false
      @_paused = false
      device.resume() for device in @devices
    
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
  
    mem_set: (addr, value) ->
      addr &= 0xffff
      value &= 0xffff
      @_mem[addr] = value
      for key, {from, to, callback} of @mem_triggers
        callback(addr, value) if from <= addr < to
  
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
      if @queue.length && !@iq_enabled && !@recent_rfi
        @trigger_interrupt @queue.shift()
      @recent_rfi = false
      unless @_halt || @sync
        # process.nextTick (=> @step()) unless @_halt || @sync
        if @_chunk++ >= 100
          @_chunk = 0
          @call_back()
          process.nextTick (=> @step()) unless @_halt || @sync
        else
          @step()
    
    call_back: ->
      reg.call_back() for reg in @all_registers
      @_cycles_callback @total_cycles
    
    on_cycles: (@_cycles_callback) ->
    
    step_over: ->
      if @next_is_jsr()
        next = @pc.get() + 1
        @step() until @_halt or @pc.get() == next
      else
        @step() unless @_halt
  
    next_is_jsr: ->
      (@mem[@pc.get()] & 0x3ff) == 0x20
  
    halt: ->
      @_halt = true
      @halt_devices()
      @callback() unless @sync
    
    halt_devices: ->
      device.halt() for device in @devices
  
    run: (callback) ->
      @callback = callback if callback
      if @sync
        @step() until @_halt
        @callback() unless @_paused
      else
        @step()
  
    dump: ->
      for value, addr in @_mem
        continue unless value
        console.log "#{addr}: #{value}"
  
    read_args: ->
      @_a.reset (@inst >> 10) & 0x3f
      if (@inst & 0x1f) != 0
        @_b.reset (@inst >> 5) & 0x1f

    perform: ->
      op = @inst & 0x1f
      @_a.get()
      if op == 0
        fun = consts.extended[(@inst >> 5) & 0x1f].toLowerCase()
        (ops[fun] || @_nul)(@_a)
      else
        fun = consts.basic[op].toLowerCase()
        (ops[fun] || @_nul)(@_b, @_a)

    mem_trigger: (from, to, callback) ->
      key = @_next_trigger++
      @mem_triggers[key] = {from, to, callback}
      key
  
    remove_mem_trigger: (key) ->
      delete @mem_triggers[key]
  