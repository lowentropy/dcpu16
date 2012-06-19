# CodeMirror mode for DCPU-16, defined as 'dasm'.
# 
# Outputs these tokens:
#   comma:     ,
#   bracket:   [ ]
#   operator:  + -
#   number:    1234, 0xdeadBEEF
#   string:    "foo \"bar\" baz"
#   comment:   ; this is a comment
#   label:     :label_3
#   register:  A, pc, etc.
#   operator:  SET, add, hwi, etc.
#   reference: label_3

(->
  registers = ['a', 'b', 'c', 'x', 'y', 'z', 'i', 'j', 'pc', 'sp', 'ex']

  instructions = [
    'set', 'add', 'sub', 'mul', 'mli', 'div', 'dvi'
    'mod', 'mdi', 'and', 'bor', 'xor', 'shr', 'asr'
    'shl', 'ifb', 'ifc', 'ife', 'ifn', 'ifg', 'ifa'
    'ifl', 'ifu', 'adx', 'sbx', 'sti', 'std', 'jsr'
    'int', 'iag', 'ias', 'rfi', 'iaq', 'hwn', 'hwq'
    'hwi', 'dat', 'require'
  ]
  
  special = [
    'push', 'pop', 'peek', 'pick'
  ]

  word_types = {}
  word_types[word] = 'register' for word in registers
  word_types[word] = 'instruction' for word in instructions
  word_types[word] = 'special' for word in special

  read_string = (stream) ->
    escape = false
    while ch = stream.next()
      break if ch == '"' && !escape
      escape = !escape && (ch == '\\')
    'string'

  read_number = (stream) ->
    if stream.peek() == 'x'
      stream.match /^x[0-9a-f]+/i
    else
      stream.match /^[0-9]*/
    'number'

  read_word = (stream) ->
    stream.match /^[a-z0-9_]+/i
    cur = stream.current().toLowerCase()
    word_types[cur] || 'reference'

  read_label = (stream) ->
    stream.match /^[\w\$_]+/
    'label'

  read_comment = (stream) ->
    stream.skipToEnd()
    'comment'

  CodeMirror.defineMode 'dasm', ->  
    token: (stream) ->    
      return null if stream.eatSpace()    
      ch = stream.next()
      if ch == ','             then 'comma'
      else if /[\[\]]/.test ch then 'bracket'
      else if /[+-]/.test ch   then 'operator'
      else if /[0-9]/.test ch  then read_number  stream
      else if ch == '"'        then read_string  stream
      else if ch == ';'        then read_comment stream
      else if ch == ':'        then read_label   stream
      else                          read_word    stream
)()