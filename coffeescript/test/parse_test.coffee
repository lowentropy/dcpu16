Program = require '../program'

compiles = (assert, str, bin) ->
  program = new Program
  program.load str
  assert.eql program.to_bin(), bin


module.exports =

  label_line_mapping: (exit, assert) ->
    program = new Program
    program.load """
      :foo set a, baz
      :bar
      :baz set a, 0
      """
    assert.equal program.lines.length, 3
    [l1, l2, l3] = program.lines
    assert.eql program.labels, {foo:l1, bar:l3, baz:l3}
    assert.eql l1.addr, 0
    assert.eql l2.addr, 2
    assert.eql l3.addr, 2
    assert.eql program.to_bin(), [0x7c01, 2, 0x8401]
  
  dat: (exit, assert) ->
    compiles assert, """
          set pc, bar
          dat 0, 0, 0
          :foo dat "foo\\n", 10, 0
          :bar set foo, bar""",
      [0x7f81, 11, 0, 0, 0, 102, 111, 111, 10, 10, 0, 0x7fe1, 11, 5]
  
  register: (exit, assert) ->
    compiles assert, "xor i, j", [0x1ccc]
  
  reg_addr: (exit, assert) ->
    compiles assert, "Add [X], 2", [0x8d62]

  reg_word_addr: (exit, assert) ->
    compiles assert, "MLI [0x2000+Y], [17 + Z]", [0x5685, 17, 0x2000]

  push_normal_form: (exit, assert) ->
    compiles assert, "set push, a", [0x0301]
  
  push_weird_form: (exit, assert) ->
    compiles assert, "set [--sp], a", [0x0301]
  
  pop_normal_form: (exit, assert) ->
    compiles assert, "set a, pop", [0x6001]

  pop_weird_form: (exit, assert) ->
    compiles assert, "set a, [sp++]", [0x6001]
  
  peek_normal_form: (exit, assert) ->
    compiles assert, "set a, peek", [0x6401]
  
  peek_weird_form: (exit, assert) ->
    compiles assert, "set a, [SP]", [0x6401]
  
  pick_normal_form: (exit, assert) ->
    compiles assert, "set a, pick 3", [0x6801, 3]

  pick_weird_form: (exit, assert) ->
    compiles assert, "set pick 0x2501, a", [0x0341, 0x2501]

  sp: (exit, assert) ->
    compiles assert, "set a, sp", [0x6c01]
  
  pc: (exit, assert) ->
    compiles assert, "set a, pc", [0x7001]
  
  ex: (exit, assert) ->
    compiles assert, "set a, ex", [0x7401]

  word_addr: (exit, assert) ->
    compiles assert, "set a, [0x2501]", [0x7801, 0x2501]
  
  word: (exit, assert) ->
    compiles assert, "set a, 31", [0x7c01, 31]

  word2: (exit, assert) ->
    compiles assert, "set a, 0x2501", [0x7c01, 0x2501]

  literal_neg: (exit, assert) ->
    compiles assert, "set a, -1", [0x8001]
  
  literal_zero: (exit, assert) ->
    compiles assert, "set a, 0", [0x8401]
  
  literal_max: (exit, assert) ->
    compiles assert, "set a, 30", [0xfc01]

  jsr: (exit, assert) ->
    compiles assert, ":loop jsr loop", [0x7c20, 0]
