module.exports = class Emulator
  constructor: ->
    for reg in 'a b c x y z i j ia sp pc ex'.split(' ')
      @[reg] = new Register reg
    @mem = (0 for i in [0x0000..0xffff])
    @devices = []
  
  load_program: (program) ->
    @mem[i] = word for word, i in program.to_bin()
    
  cycles: (n) ->
    @_cycles += n
  
  send_interrupt: (hw_idx) ->
    @devices[hw_idx]?.send_interrupt()
  
  trigger_interrupt: (message) ->
    if 0 != (ia = @ia.get())
      @enable_iq()
      @push @pc.get
      @push @a.get
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
  
  pop: ->
    value = @mem_get @sp.get()
    @sp.set @sp.get() + 1
    value
  
  skip: ->
    @_skip = true
    @cycles 1
    @pc.set @pc.get + 1
    @skip() if @instruction_is_if()

  instruction_is_if: ->
    # TODO
  
  enable_iq: ->
    @iq_enabled = true
  
  disable_id: ->
    @iq_enabled = false


class Register
  constructor: (@name) ->
    @value = 0
  
  get: ->
    @value
  
  set: (value) ->
    @value = value & 0xffff
