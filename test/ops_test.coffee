Program = require '../program'
Emulator = require '../emulator'
DummyDevice = require '../devices/dummy'
consts = require '../consts'
_assert = require 'assert'

run = (assert, str, values) ->
  assert ?= _assert
  emu = new Emulator
  prog = new Program sync: true
  prog.load str
  emu.load_program prog
  emu.attach_device new DummyDevice(emu)
  emu.run ->
    mem = values.mem ? {}
    delete values.mem
    for name, value of values
      assert.eql emu[name].get(), value, "Expected #{name} to be #{value}, but got #{emu[name].get()}"
    for addr, value of mem
      actual = emu.mem_get(parseInt(addr))
      assert.eql actual, value, "Expected mem #{addr} to be #{value}, but got #{actual}"

is_yes = (assert, str) ->
  run assert, "set a, 3\n#{str}\nset a, 5", a: 5

is_no = (assert, str) ->
  run assert, "set a, 3\n#{str}\nset a, 5", a: 3

module.exports =

  check_defaults: (e,a) ->
    run a, "", a:0, b:0, c:0, x:0, y:0, z:0, sp:0, pc:1, ex:0

  set_to_small_const: (e,a) ->
    run a, "set a, 23", a: 23
  
  add_two_small_ints: (e,a) ->
    run a, "set ex, 3\nset a, 2\nadd a, 3", a: 5, ex: 0

  set_from_b_to_a: (e,a) ->
    run a, "set b, 17\nset a, b", a: 17, b: 17
  
  add_overflow: (e,a) ->
    run a, "set a, 0xffff\nadd a, 2", a: 1, ex: 1, pc: 4
  
  sub: (e,a) ->
    run a, "set ex, 3\nset a, 17\nset b, 5\nsub a, b", a: 12, b: 5, ex: 0
  
  sub_underflow: (e,a) ->
    run a, "set ex, 3\nset a, 3\nsub a, 5", a: 0xfffe, ex: 0xffff

  mul: (e,a) ->
    run a, "set ex, 3\nset a, 7\nmul a, 19", a: 133, ex: 0
  
  mul_overflow: (e,a) ->
    run a, "set ex, 3\nset a, 0x9f37\nmul a, 0x30ca", a: 0xf166, ex: 0x1e57

  mli: (e,a) ->
    run a, "set ex, 3\nset a, 3\nset b, -5\nmli a, b",
      b: ((-5)&0xffff), a: ((-15)&0xffff), ex: 0xffff
  
  mli_positive_overflow: (e,a) ->
    run a, "set ex, 3\nset a, 0x7f37\nmli a, 0x30ca", a: 0xb166, ex: 0x183e

  mli_negative_overflow: (e,a) ->
    run a, "set ex, 3\nset a, 0x9f37\nmli a, 0x30ca", a: 0xf166, ex: 0xed8d
  
  div: (e,a) ->
    run a, "set ex, 3\nset a, 5\ndiv a, 2", a: 2, ex: 0x8000
  
  div_3: (e,a) ->
    run a, "set ex, 3\nset a, 5\ndiv a, 3", a: 1, ex: 0xaaaa
  
  div_0: (e,a) ->
    run a, "set ex, 3\nset a, 5\ndiv a, 0", a: 0, ex: 0
  
  div_large: (e,a) ->
    run a, "set ex, 3\nset a, 0xffff\ndiv a, 2", a: 0x7fff, ex: 0x8000

  # NOTE: spec says to round toward zero, but that really doesn't make much sense;
  # for instance, 0xffff (-1) / 2 would result in 0 with ex 0x8000; which is the SAME
  # as you would get for 0x0001 (1) / 2 ! rounding down makes more sense. You can
  # then always treat EX as an unsigned positive addition to the result, i.e. in the
  # first case above, the answer is 0xffff (-1) plus .100..., i.e. -1 + 0.5 = -0.5
  dvi: (e,a) ->
    run a, "set ex, 3\nset a, -5\ndvi a, 2", a: 0xfffd, ex: 0x8000

  dvi_negs: (e,a) ->
    run a, "set ex, 3\nset a, -5\ndvi a, -2", a: 2, ex: 0x8000
  
  dvi_0: (e,a) ->
    run a, "set ex, 3\nset a, -23\ndvi a, 0", a: 0, ex: 0
  
  mod: (e,a) ->
    run a, "set a, 17\nmod a, 3", a: 2
  
  mod_0: (e,a) ->
    run a, "set a, 17\nmod a, 0", a: 0
  
  mdi: (e,a) ->
    run a, "set a, -7\nmdi a, 16", a: 0xfff9

  mdi_negs: (e,a) ->
    run a, "set a, -7\nmdi a, -16", a: 0xfff9
  
  and: (e,a) ->
    run a, "set a, 0xdead\nand a, 0xbeef", a: 0x9ead
  
  bor: (e,a) ->
    run a, "set a, 0xdead\nbor a, 0xbeef", a: 0xfeef
  
  xor: (e,a) ->
    run a, "set a, 0xdead\nxor a, 0xbeef", a: 0x6042

  shr: (e,a) ->
    run a, "set a, 0xdead\nshr a, 4", a: 0x0dea, ex: 0xd000
  
  shr_weird: (e,a) ->
    run a, "set a, 0xdead\nshr a, 11", a: 0x01b, ex: 0xd5a0
  
  asr: (e,a) ->
    run a, "set a, 0xdead\nasr a, 4", a: 0xfdea, ex: 0xd000

  asr_pos: (e,a) ->
    run a, "set a, 0x7ead\nasr a, 4", a: 0x07ea, ex: 0xd000
  
  shl: (e,a) ->
    run a, "set a, 0xdead\nshl a, 11", a: 0x6800, ex: 0x06f5

  ifb_yes: (e,a) -> is_yes a, 'ifb 1, 1'
  ifb_no: (e,a) -> is_no a, 'ifb 1, 0'
  
  ifc_yes: (e,a) -> is_yes a, 'ifc 1, 0'
  ifc_yes2: (e,a) -> is_yes a, 'ifc 0, 0'
  ifc_no: (e,a) -> is_no a, 'ifc 1, 1'
  
  ife_yes: (e,a) -> is_yes a, 'ife 17, 17'
  ife_no: (e,a) -> is_no a, 'ife 17, 15'

  ifn_yes: (e,a) -> is_yes a, 'ifn 17, 15'
  ifn_no: (e,a) -> is_no a, 'ifn 17, 17'
  
  ifg_yes: (e,a) -> is_yes a, 'ifg -1, 5'
  ifg_no: (e,a) -> is_no a, 'ifg 5, -1'
  ifg_no2: (e,a) -> is_no a, 'ifg 17, 17'
  
  ifa_yes: (e,a) -> is_yes a, 'ifa 5, -1'
  ifa_no: (e,a) -> is_no a, 'ifa -1, 5'
  ifa_no2: (e,a) -> is_no a, 'ifa -17, -17'
  
  ifl_yes: (e,a) -> is_yes a, 'ifl 5, -1'
  ifl_no: (e,a) -> is_no a, 'ifl -1, 5'
  ifl_no2: (e,a) -> is_no a, 'ifl 17, 17'
  
  ifu_yes: (e,a) -> is_yes a, 'ifu -1, 5'
  ifu_no: (e,a) -> is_no a, 'ifu 5, -1'
  ifu_no2: (e,a) -> is_no a, 'ifu -17, -17'
    
  if_skips: (e,a) -> is_no a, "ife 1,2\nife 1,1"
  if_slides: (e,a) -> is_yes a, "ifn 1,2\nife 3,3"
  if_abort: (e,a) -> is_no a, "ifn 1,2\nife 3,4"
  
  adx: (e,a) ->
    run a, "set a, 7\nset ex, 4\nadx a, 9", a: 20, ex: 0
  
  adx_overflow: (e,a) ->
    run a, "set ex, 3\nset a, 0x8000\nset ex, 0x7fff\nadx a, 5", a: 4, ex: 1
  
  sbx: (e,a) ->
    run a, "set ex, 3\nset a, 3\nset ex, 7\nsbx a, 4", a: 6, ex: 0
  
  sbx_underflow: (e,a) ->
    run a, "set ex, 3\nset a, 3\nset ex, 2\nsbx a, 9", a: 0xfffc, ex: 0xffff
  
  sti: (e,a) ->
    run a, "set i,1\nset j,2\nsti a,5", a: 5, i: 2, j: 3
  
  std: (e,a) ->
    run a, "set j,1\nstd a,5", a: 5, i: 0xffff, j: 0
  
  jsr: (e,a) ->
    run a, "set a,a\njsr 2\njsr 13", pc: 14, mem: {0xffff: 2, 0xfffe: 3}

  int_no_ia: (e,a) ->
    run a, "int 13", a: 0, ia: 0, pc: 2, sp: 0
  
  int_with_ia: (e,a) ->
    run a, "set a, 7\nias 0x2501\nint 13", a: 13, pc: 0x2502, sp: 0xfffe, mem: {0xffff: 4, 0xfffe: 7}

  ias_iag: (e,a) ->
    run a, "ias 412\niag a", a: 412
  
  rfi: (e,a) ->
    run a, "set a,7\nias 5\nint 13\nset a,b\ndat 0\nset b,a\nrfi 0", a: 13, pc: 5, ia: 5
  
  hwn: (e,a) ->
    run a, "hwn a", a: 1

  hwq: (e,a) ->
    run a, "hwq 0", b: 0xdead, a: 0xbeef, c: 0x1337, y: 0xf007, x: 0xba11
  
  hwi: (e,a) ->
    run a, "hwi 0", a: 1, b: 2, c: 3, x: 4, y: 5, z: 6, i: 7, j: 8
  
  # TODO: remove me!
  print: (e,a) ->
    run a, "print 216", {}

  conditional_pop: (e,a) ->
    run a, "ife 1, 2\nset a, pop", sp: 0

