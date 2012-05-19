# --- Values: (5/6 bits) ---------------------------------------------------------
#  C | VALUE     | DESCRIPTION
# ---+-----------+----------------------------------------------------------------
#  0 | 0x00-0x07 | register (A, B, C, X, Y, Z, I or J, in that order)
#  0 | 0x08-0x0f | [register]
#  1 | 0x10-0x17 | [register + next word]
#  0 |      0x18 | (PUSH / [--SP]) if in b, or (POP / [SP++]) if in a
#  0 |      0x19 | [SP] / PEEK
#  1 |      0x1a | [SP + next word] / PICK n
#  0 |      0x1b | SP
#  0 |      0x1c | PC
#  0 |      0x1d | EX
#  1 |      0x1e | [next word]
#  1 |      0x1f | next word (literal)
#  0 | 0x20-0x3f | literal value 0xffff-0x1e (-1..30) (literal) (only for a)
#  --+-----------+----------------------------------------------------------------

require 'consts'

class Value
  attr_reader :type, :register, :next_word, :literal, :position
  attr_accessor :emu, :source

  def initialize type, position, register=nil, const=nil
    @type = type
    @position = position
    @register = register
    if type == :literal
      @literal = const
    else
      @next_word = const
    end
  end

  def cell
    @cell ||= case type
    when :reg
      emu.register register
    when :reg_addr
      emu.address emu.register(register).get
    when :reg_word_addr
      emu.address emu.register(register).get + next_word
    when :push
      emu.address emu.sp.pre.dec
    when :pop
      emu.address emu.sp.post.inc
    when :peek
      emu.address emu.sp.get
    when :pick
      emu.address emu.sp.get + next_word
    when :sp, :pc, :ex
      emu.send type
    when :word_addr
      emu.address next_word
    when :word
      ConstCell.new next_word
    when :literal
      ConstCell.new literal
    end
  end
  
  def get
    cell.get
  end
  
  def set value
    cell.set value
  end
  
  def const
    if type == :literal
      literal
    else
      next_word
    end
  end
  
  def next_word?
    [:reg_word_addr, :word_addr, :word, :pick].include? type
  end
  
  def to_asm
    case type
    when :reg then REGISTERS[register]
    when :reg_addr then "[#{REGISTERS[register]}]"
    when :reg_word_addr then "[#{HEX % next_word}+#{REGISTERS[register]}]"
    when :push, :pop, :peek, :sp, :pc, :ex then type.to_s.upcase
    when :pick then "PICK #{next_word}"
    when :word_addr then "[#{HEX % next_word}]"
    when :word then HEX % next_word
    when :literal then HEX % literal
    end
  rescue
    puts "Error with: #{inspect}"
    fail
  end
  
  def to_bin
    case type
    when :reg then register
    when :reg_addr then register + 0x08
    when :reg_word_addr then register + 0x10
    when :push, :pop then 0x18
    when :peek then 0x19
    when :pick then 0x1a
    when :sp then 0x1b
    when :pc then 0x1c
    when :ex then 0x1d
    when :word_addr then 0x1e
    when :word then 0x1f
    when :literal then literal + 0x21
    end
  end
  
  def self.from_asm asm, pos
    case asm
    when /^(push|pop|peek|sp|pc|ex)$/i
      Value.new asm.downcase.to_sym, pos
    when /^pick\s+(.*)$/i
      Value.new :pick, pos, nil, $1.to_i
    when /^\[(.*)\]$/
      if $1.include? '+'
        const, reg = $1.split '+'
        Value.new :reg_word_addr, pos, dereg(reg), deconst(const)
      elsif $1.include? '0'
        Value.new :word_addr, pos, nil, deconst($1)
      else
        Value.new :reg_addr, pos, dereg($1)
      end
    when /[0-9]/
      num = deconst asm
      if num < 0x20
        Value.new :literal, pos, nil, num
      else
        Value.new :word, pos, nil, num
      end
    else
      Value.new :reg, pos, dereg(asm)
    end.tap do |value|
      value.source = asm
    end
  end
  
  def self.from_bin bin, word, pos
    case bin
    when 0x00..0x07
      Value.new :reg, pos, bin
    when 0x08..0x0f
      Value.new :reg_addr, pos, bin - 0x08
    when 0x10..0x17
      Value.new :reg_word_addr, pos, bin - 0x10, word
    when 0x18
      Value.new (pos == :a ? :pop : :push), pos
    when 0x19
      Value.new :peek, pos
    when 0x1a
      Value.new :pick, pos, nil, word
    when 0x1b..0x1d
      Value.new [:sp, :pc, :ex][bin - 0x1b], pos
    when 0x1e
      Value.new :word_addr, pos, nil, word
    when 0x1f
      Value.new :word, pos, nil, word
    else
      Value.new :literal, pos, nil, bin-0x21
    end
  end
  
  def self.dereg reg
    REGISTERS.index reg.to_s.strip.upcase
  end
  
  def self.deconst const
    eval const.to_s.strip
  end
end