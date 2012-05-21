require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './ops', (require, module, exports, __dirname, __filename) ->

  emu = null

  rnd = (x) ->
    Math.floor(x) # if x < 0 then Math.ceil(x) else Math.floor(x)

  signed = (x) ->
    if x > 0x7fff
      x - 0x10000
    else
      x

  module.exports =
    init: (e) ->
      emu = e
  
    set: (b, a) ->
      emu.cycles 1
      b.set a.get()
  
    add: (b, a) ->
      emu.cycles 2
      b.set(sum = b.get() + a.get())
      emu.ex.set(if sum > 0xffff then 1 else 0)
  
    sub: (b, a) ->
      emu.cycles 2
      b.set(dif = b.get() - a.get())
      emu.ex.set(if dif < 0 then 0xffff else 0)
  
    mul: (b, a) ->
      emu.cycles 2
      b.set(prd = b.get() * a.get())
      emu.ex.set prd >> 16
  
    mli: (b, a) ->
      emu.cycles 2
      b.set(prd = signed(b.get()) * signed(a.get()))
      emu.ex.set prd >> 16
  
    div: (b, a) ->
      emu.cycles 3
      if a.get() == 0
        b.set 0
        emu.ex.set 0
      else
        b.set(qot = rnd(b.get() / a.get()))
        emu.ex.set rnd((b.get() << 16) / a.get())
  
    dvi: (b, a) ->
      emu.cycles 3
      if a.get() == 0
        b.set 0
        emu.ex.set 0
      else
        b.set(qot = rnd(signed(b.get()) / signed(a.get())))
        emu.ex.set rnd((signed(b.get()) << 16) / signed(a.get()))
  
    mod: (b, a) ->
      emu.cycles 3
      if a.get() == 0
        b.set 0
      else
        b.set b.get() % a.get()
  
    mdi: (b, a) ->
      emu.cycles 3
      if a.get() == 0
        b.set 0
      else
      b.set signed(b.get()) % signed(a.get())
  
    and: (b, a) ->
      emu.cycles 1
      b.set b.get() & a.get()
  
    bor: (b, a) ->
      emu.cycles 1
      b.set b.get() | a.get()
  
    xor: (b, a) ->
      emu.cycles 1
      b.set b.get() ^ a.get()
  
    shr: (b, a) ->
      emu.cycles 1
      b.set b.get() >>> a.get()
      emu.ex.set (b.get() << 16) >> a.get()
  
    asr: (b, a) ->
      emu.cycles 1
      b.set signed(b.get()) >> a.get()
      emu.ex.set (b.get() << 16) >>> a.get()
  
    shl: (b, a) ->
      emu.cycles 1
      b.set b.get() << a.get()
      emu.ex.set (b.get() << a.get()) >> 16
  
    ifb: (b, a) ->
      emu.cycles 2
      emu.skip() unless (b.get() & a.get()) != 0
  
    ifc: (b, a) ->
      emu.cycles 2
      emu.skip() unless (b.get() & a.get()) == 0
  
    ife: (b, a) ->
      emu.cycles 2
      emu.skip() unless b.get() == a.get()
  
    ifn: (b, a) ->
      emu.cycles 2
      emu.skip() unless b.get() != a.get()
  
    ifg: (b, a) ->
      emu.cycles 2
      emu.skip() unless b.get() > a.get()
  
    ifa: (b, a) ->
      emu.cycles 2
      emu.skip() unless signed(b.get()) > signed(a.get())
  
    ifl: (b, a) ->
      emu.cycles 2
      emu.skip() unless b.get() < a.get()
  
    ifu: (b, a) ->
      emu.cycles 2
      emu.skip() unless signed(b.get()) < signed(a.get())
  
    adx: (b, a) ->
      emu.cycles 3
      b.set(sum = b.get() + a.get() + emu.ex.get())
      emu.ex.set(if sum > 0xffff then 1 else 0)
  
    sbx: (b, a) ->
      emu.cycles 3
      b.set(dif = b.get() - a.get() + emu.ex.get())
      emu.ex.set(if dif < 0 then 0xffff else 0)
  
    sti: (b, a) ->
      emu.cycles 2
      b.set a.get()
      emu.i.set emu.i.get() + 1
      emu.j.set emu.j.get() + 1
  
    std: (b, a) ->
      emu.cycles 2
      b.set a.get()
      emu.i.set emu.i.get() - 1
      emu.j.set emu.j.get() - 1
  
    jsr: (a) ->
      emu.cycles 3
      emu.push emu.pc.get()
      emu.pc.set a.get()
  
    int: (a) ->
      emu.cycles 4
      emu.trigger_interrupt a.get()
  
    iag: (a) ->
      emu.cycles 1
      a.set emu.ia.get()
  
    ias: (a) ->
      emu.cycles 1
      emu.ia.set a.get()
  
    rfi: (a) ->
      emu.cycles 3
      emu.disable_iq()
      a.set emu.pop()
      emu.pc.set emu.pop()
      emu.recent_rfi = true
  
    iaq: (a) ->
      emu.cycles 2
      if a.get() != 0
        emu.enable_iq()
      else
        emi.disable_iq()
  
    hwn: (a) ->
      emu.cycles 2
      a.set emu.num_devices()
  
    hwq: (a) ->
      emu.cycles 4
      emu.get_device_info a.get()
  
    hwi: (a) ->
      emu.cycles 4
      emu.send_interrupt a.get()
  
    # TODO: REMOVE ME!
    print: (a) ->
      emu.cycles 4
      console.log "DCPU: #{a.get()}"
