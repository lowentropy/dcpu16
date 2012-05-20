class Emulator
  attr_reader :sp, :pc, :ex, :ia
  def initialize
    @sp, @pc, @ex, @ia = Array.new(4) { Cell.new }
    @registers = Array.new(8) { Cell.new }
    @memory = {}
  end
  def register i
    @registers[i]
  end
  def address addr
    @memory[addr] ||= Cell.new
  end
  %w(a b c x y z i j).each_with_index do |name, index|
    define_method(name) { register index }
  end
end