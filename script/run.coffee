tty = require 'tty'
Emulator = require '../lib/emulator'
Program = require '../lib/program'
GenericClock = require '../lib/devices/clock'
TTYKeyboard = require '../lib/devices/keyboard'

emu = new Emulator
program = new Program

program.load_from_file process.argv[2]
emu.load_program program

clock = new GenericClock emu
emu.attach_device clock

kb = new TTYKeyboard emu
emu.attach_device kb

process.stdin.resume()
tty.setRawMode true
process.stdin.on 'keypress', (char, key) =>
  process.exit() if key?.ctrl && key.name == 'c'

kb.start()

start = new Date()
emu.run ->
  ms = new Date() - start
  console.log 'freq =', emu.total_cycles / ms, 'kHz'
  process.exit()
