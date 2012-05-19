HEX = "0x%04x"
REGISTERS = %w(A B C X Y Z I J)
OPCODES = [
  :special, :set, :add, :sub, :mul, :mli, :div, :dvi,
  :mod, :mdi, :and, :bor, :xor, :shr, :asr, :shl,
  :ifb, :ifc, :ife, :ifn, :ifg, :ifa, :ifl, :ifu,
  nil, nil, :adx, :sbx, nil, nil, :sti, :std
]
EXT_OPCODES = [
  :reserved, :jsr, nil, nil, nil, nil, nil, nil,
  :int, :iag, :ias, :rfi, :iaq, nil, nil nil,
  :hwn, :hwq, :hwi
]