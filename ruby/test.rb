require 'assembler'

p = Program.new
p.load_file File.read('test.S')

puts p.to_bin.map {|arr| arr.map {|n| "%04x" % n}}.inspect