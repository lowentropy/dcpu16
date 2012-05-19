require 'consts'
require 'value'

class Program
  attr_reader :ops, :labels
  
  def load_file file
    @labels = {}
    @lines = []
    @line = 1
    file.split(/\n+/).each &method(:process_line)
    @ops = finish_lines
  end
  
  def process_line line
    line = line.gsub(/;.*$/, '').strip
    if line =~ /^:([^\s]+)/
      len = $1.size + 1
      label = Label.new line[1,len-1]
      @labels[label.name] = label
      line = line[len..-1].strip
    end
    op, *parts = line.split(/[\s,]+/)
    return unless op
    line = @line
    @line += 1
    @lines << [line, label, op, parts]
  end
  
  def finish_lines
    @addr = 0
    @lines.map do |(line, label, op, parts)|
      pos = (parts.size == 2)  ? [:b, :a] : [:a]
      unless (op = op.downcase.to_sym) == :dat
        parts.map! {|w| @labels[w] || Value.from_asm(w, pos.shift) }
      end
      op = Operation.new @addr, op, parts, label, line
      @addr += op.size
      op
    end
  end
  
  def to_bin
    @ops.map &:to_bin
  end
end

class Label < Value
  attr_reader :name
  attr_accessor :addr
  def initialize name
    @name = name
  end
  def get; addr; end
  def set; end
  def to_asm; name; end
  # TODO: it would be cool to have short-form label constants, but we can't
  # because we don't know if a future label is <= 0x20, *because* we don't know
  # the size of the operator that references it! (plus thos in between them)
  def to_bin
    0x1f # (addr < 0x20) ? (addr + 0x20) : 0x1f
  end 
  def next_word?
    true # addr >= 0x20
  end
  def next_word
    addr
  end
  def to_s
    ":#{name} "
  end
end

class Operation
  attr_reader :addr, :type, :parts, :label, :emu, :line
  
  def initialize addr, type, parts, label, line
    @addr = addr
    @type = type
    @parts = parts
    @label = label
    @line = line
    label.addr = addr if label
  end
  
  def dat
    @dat ||= eval(parts[0])
  end
  
  def size
    @size ||= if dat?
      dat.size
    else
      1 + parts.select(&:next_word?).size
    end
  end
  
  def to_asm
    if dat?
      "#{label}DAT \"#{@dat}\", 0"
    else
      "#{label}#{type.to_s.upcase} #{parts.map(&:to_asm).join(', ')}"
    end
  end
  
  def extended?
    @extended ||= (EXT_OPCODES.include? type)
  end
  
  def a
    parts[1]
  end
  
  def b
    parts[0]
  end
  
  def to_bin
    bin = if extended?
      (a.to_bin << 10) | (ext_opcode << 5) | 0
    else
      (b.to_bin << 10) | (a.to_bin << 5) | opcode
    end
    bin = [bin]
    bin << a.const if a && a.next_word?
    bin << b.const if b && b.next_word?
    bin
  end
  
  def opcode
    OPCODES.index type
  end
  
  def ext_opcode
    EXT_OPCODES.index type
  end
  
  def clear
    @a_ = nil
    @b_ = nil
  end

  def a_
    @a_ ||= a.get
  end
  
  def b_
    a_
    @b_ ||= b.get
  end

  def set
    b.set a_
  end
  
  def add
    b.set(sum = b_ + a_)
    emu.ex.set(sum > 0xffff ? 1 : 0)
  end
  
  def sub
    b.set(dif = b_ - a_)
    emu.ex.set(dif < 0 ? 0xffff : 0)
  end
  
  def mul
    b.set(prd = b_ * a_)
    emu.ex.set(prd >> 16)
  end
  
  def mli
    b.set(prd = sb_ * sa_)
    emu.ex.set(prd >> 16)
  end

  def div
    if a_ == 0
      b.set 0
      emu.ex.set 0
    else
      b.set(qot = b_ / a_)
      emu.ex.set((b_ << 16) / a_)
    end
  end
  
  def dvi
    if a_ == 0
      b.set 0
      emu.ex.set 0
    else
      b.set(qot = (sb_.to_f / sa_).truncate)
      emu.ex.set(((sb_ << 16).to_f / sa_).truncate)
    end
  end
  
  def mod
    if a_ == 0
      b.set 0
    else
      b.set b_ % a_
    end
  end
  
  def mdi
    if a_ == 0
      b.set 0
    else
      mod = sb_ % sa_
      mod -= sa_ if sb_ < 0 && sa_ > 0
      b.set mod
    end
  end
  
  def and
    b.set b_ & a_
  end
  
  def bor
    b.set b_ | a_
  end
  
  def xor
    b.set b_ ^ a_
  end
  
  def shr
    b.set logical_shift(b_, a_)
    emu.ex.set arith_shift(b_ << 16, a_)
  end
  
  def asr
    b.set arith_shift(b_, a_)
    emu.ex.set logical_shift(b_ << 16, a_)
  end
  
  def shl
    b.set b_ << a_
    emu.ex.set arith_shift(b_ << a_, 16)
  end
  
  def ifb
    emu.skip unless (b_ & a_) != 0
  end
  
  def ifc
    emu.skip unless (b_ & a_) == 0
  end
  
  def ife
    emu.skip unless b_ == a_
  end
  
  def ifn
    emu.skip unless b_ != a_
  end
  
  def ifg
    emu.skip unless b_ > a_
  end
  
  def ifa
    emu.skip unless sb_ > sa_
  end
  
  def ifl
    emu.skip unless b_ < a_
  end
  
  def ifu
    emu.skip unless sb_ < sa_
  end
  
  def adx
    b.set(sum = b_ + a_ + emu.ex.get)
    emu.ex.set(sum > 0xffff ? 1 : 0)
  end
  
  def sbx
    b.set(dif = b_ - a_ + emu.ex.get)
    emu.ex.set(dif < 0 ? 0xffff : 0)
  end
  
  def sti
    b.set a_
    emu.i.post.inc
    emu.j.post.inc
  end
  
  def std
    b.set a_
    emu.i.post.dec
    emu.j.post.dec
  end
  
  def jsr
    addr = emu.address emu.sp.pre.dec
    addr.set emu.pc.get + 1
    emu.pc.set a_
  end
  
  def int
    emu.interrupt a_
  end
  
  def iag
    a.set emu.ia.get
  end
  
  def ias
    emu.ia.set a_
  end
  
  def rfi
    emu.disable_interrupt_queueing!
  end
  
  private

  def logical_shift(x, b)
    x >> b
  end
  
  def arith_shift(x, b)
    bit = x & 0x8000
    b.times { x = (x >> 1) | bit }
    x
  end
    
  # BLAHBLAHBLAH
  
  #     0x7: SHL a, b - sets a to a<<b, sets O to ((a<<b)>>16)&0xffff
  def shl
    a.set(sh = a.get << b.get)
    emu.o.set((sh >> 16) & 0xffff)
  end
  
  #     0x8: SHR a, b - sets a to a>>b, sets O to ((a<<16)>>b)&0xffff
  def shr
    a.set((a_ = a.get) >> (b = self.b.get))
    emu.o.set(((a_ << 16) >> b) & 0xffff)
  end
  
  #     0xc: IFE a, b - performs next instruction only if a==b
  def ife
    emu.skip unless a.get == b.get
  end
  
  #     0xd: IFN a, b - performs next instruction only if a!=b
  def ifn
    emu.skip unless a.get != b.get
  end
  
  #     0xe: IFG a, b - performs next instruction only if a>b
  def ifg
    emu.skip unless a.get > b.get
  end
  
  #     0xf: IFB a, b - performs next instruction only if (a&b)!=0
  def ifb
    emu.skip unless (a.get & b.get) != 0
  end
end
