# CodeMirror mode for DCPU-16, defined as 'dcpu'.
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

  operators = [
    'set', 'add', 'sub', 'mul', 'mli', 'div', 'dvi'
    'mod', 'mdi', 'and', 'bor', 'xor', 'shr', 'asr'
    'shl', 'ifb', 'ifc', 'ifn', 'ifg', 'ifa', 'ifl'
    'ifu', 'adx', 'sbx', 'sti', 'std', 'jsr', 'int'
    'iag', 'ias', 'rfi', 'iaq', 'hwn', 'hwq', 'hwi'
  ]

  word_types = {}
  word_types[word] = 'register' for word in registers
  word_types[word] = 'operator' for word in operators

  read_string = (stream) ->
    escape = false
    while ch = stream.next()
      break if ch == '"' && !escape
      escape = !escape && (ch == '\\')
    'string'

  read_number = (stream) ->
    stream.match /[x0-9]+/i
    'number'

  read_word = (stream) ->
    stream.match /[\w\$_]+/
    cur = stream.current().toLowerCase()
    word_type[cur] || 'reference'

  read_label = (stream) ->
    stream.match /[\w\$_]+/
    'label'

  read_comment = (stream) ->
    stream.skipToEnd()
    'comment'

  CodeMirror.defineMode 'dcpu', ->  
    token: (stream) ->    
      return null if stream.eatSpace()    
      ch = stream.next()
      if ch == ','            then 'comma'
      else if /\[\]/.test  ch then 'bracket'
      else if /\+\-/.test  ch then 'operator'
      else if /[0-9]/.test ch then read_number  stream
      else if ch == '"'       then read_string  stream
      else if ch == ';'       then read_comment stream
      else if ch == ':'       then read_label   stream
      else                         read_word    stream
)()