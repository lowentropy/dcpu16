fs = require 'fs'
consts = require './consts'


module.exports = class Program
  
  constructor: ->
    @filename = '<raw>'
    @labels = {}
  
  load_from_file: (@filename) ->
    @load fs.readFileSync(@filename).toString()
  
  load: (@raw) ->
    @split_lines()
    @record_labels()
    @parse_lines()
    @assign_addresses()
    @compile()
  
  split_lines: ->
    @lines = []
    for line, index in @raw.split "\n"
      @lines.push(new Line this, line, index+1) if line.length
    # @lines.pop() unless @lines[@lines.length - 1]
  
  record_labels: ->
    labels = []
    for line in @lines
      labels = labels.concat line.labels
      continue if line.empty()
      @labels[label] = line for label in labels
      labels = []
  
  resolve_label: (label) ->
    @labels[label]?.addr ? throw new Error "Unknown label: #{label}"
  
  parse_lines: ->
    line.parse() for line in @lines
  
  assign_addresses: ->
    addr = 0
    for line in @lines
      line.set_addr addr
      addr += line.size()
    @size = addr
  
  compile: ->
    @bin = (0 for i in [1..@size])
    addr = 0
    for line in @lines
      @bin[addr++] = word for word in line.to_bin()
  
  to_bin: ->
    @bin


class Line
  constructor: (@program, @raw, @lineno) ->
    @labels = []
    @str = @raw
    @remove_comments()
    @parse_labels()
    @split()
  
  remove_comments: ->
    if -1 < (idx = @str.indexOf ';')
      @comment = @str.substring idx+1
      @str = @str.substring 0, idx
  
  parse_labels: ->
    re = /^\s*:(\w+)/
    while m = re.exec(@str)
      [text, label] = m
      @str = @str.substring text.length
      @labels.push label

  split: ->
    if (@str = @str.trim()).length
      m = @str.match /^([^\s]+)\s+(.*)$/
      @op = m[1]
      @parts = m[2].split(/,\s*/)
  
  empty: ->
    !@op?
  
  parse: ->
    @contents = if @empty()
      new Noop
    else if /dat/i.test @op
      new Dat @parts
    else
      new Operation this, @op, @parts
  
  set_addr: (@addr) ->
  
  to_bin: -> @contents.to_bin()
  size: -> @contents.size()


class Noop
  to_bin: -> []
  size: -> 0


class Dat
  constructor: (@parts) ->
    @extract_words()
  
  extract_words: ->
    @words = []
    for part in @parts
      if /^".*"$/.test part
        @append_string eval(part)
      else
        @words.push parseInt(part)

  append_string: (str) ->
    for i in [0...str.length]
      @words.push str.charCodeAt(i)
  
  size: ->
    @words.length
  
  to_bin: ->
    @words


class Operation
  constructor: (@line, op, parts) ->
    @op = op.toUpperCase()
    @a = new Value this, parts.pop(), 'a'
    @b = new Value this, parts.pop(), 'b' if parts.length
    
  assemble: ->
    @word = @a.to_bin() << 10
    if @extended()
      @word |= (@extended_opcode() << 5)
    else
      @word |= (@b.to_bin() << 5)
      @word |= @basic_opcode()
    @_words = [@word]
    @_words.push @a.next_word() if @a.next
    @_words.push @b.next_word() if @b?.next
  
  extended: ->
    @_extended ?= (consts.extended.indexOf(@op) >= 0)
  
  basic_opcode: ->
    consts.basic.indexOf @op
  
  extended_opcode: ->
    consts.extended.indexOf @op
  
  words: ->
    @assemble() unless @_words
    @_words
  
  size: ->
    1 + (if @a.next then 1 else 0) + (if @b?.next then 1 else 0)
  
  to_bin: ->
    @words()


class Value
  constructor: (@op, @raw, @pos) ->
    @identify()
  
  identify: ->
    if @raw.match /^(push|pop|peek|sp|pc|ex)$/i
      @type = @raw.toLowerCase()
    else if @raw.match /^\[--sp\]$/i
      @type = 'push'
    else if @raw.match /^\[sp\+\+\]$/i
      @type = 'pop'
    else if @raw.match /^\[sp\]$/i
      @type = 'peek'
    else if m = @raw.match /^pick\s+(.*)/i
      @type = 'pick'
      @next = m[1]
    else if m = @raw.match /^\[(.*)\]$/
      @identify_addr m[1].trim()
    else if @raw.match /^[abcxyzij]$/i
      @type = 'reg'
      @register = @dereg @raw
    else
      @identify_const()
  
  identify_const: ->
    num = parseInt @raw
    if (@pos == 'a') && ((num == 0) || (num && -2 < num < 31))
      @type = 'literal'
      @literal = num
    else
      @type = 'word'
      @next = @raw
  identify_addr: (raw) ->
    if raw.indexOf('+') >= 0
      [offset, reg] = raw.split '+'
      if reg.match /sp/i
        @type = 'pick'
      else
        @type = 'reg_word_addr'
        @register = @dereg reg
      @next = offset.trim()
    else if raw.match /^[abcxyzij]$/i
      @type = 'reg_addr'
      @register = @dereg raw
    else
      @type = 'word_addr'
      @next = raw
  
  to_bin: ->
    switch @type
      when 'reg' then @register
      when 'reg_addr' then @register + 0x08
      when 'reg_word_addr' then @register + 0x10
      when 'push', 'pop' then 0x18
      when 'peek' then 0x19
      when 'pick' then 0x1a
      when 'sp' then 0x1b
      when 'pc' then 0x1c
      when 'ex' then 0x1d
      when 'word_addr' then 0x1e
      when 'word' then 0x1f
      when 'literal' then (@literal + 0x21) & 0x3f
  
  dereg: (str) ->
    consts.registers.indexOf str.trim().toUpperCase()

  next_word: ->
    num = parseInt(@next)
    if num || (num == 0)
      num & 0xffff
    else
      @op.line.program.resolve_label @next
