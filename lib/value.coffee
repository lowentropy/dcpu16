consts = require './consts'

module.exports = class Value
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
