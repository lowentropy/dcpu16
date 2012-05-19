Emulator = require './emulator'
Program = require './program'
GenericClock = require './devices/clock'
TTYKeyboard = require './devices/keyboard'

emu = new Emulator
program = new Program

program.load_from_file process.argv[2]
emu.load_program program

clock = new GenericClock emu
emu.attach_device clock

kb = new TTYKeyboard emu
emu.attach_device kb

kb.start()

start = new Date()
emu.run ->
  ms = new Date() - start
  console.log 'freq =', emu.total_cycles / ms, 'kHz'
  process.exit()
