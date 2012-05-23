#= require ../../lib/require-define
#= require_tree ../../lib

Program = require './program'
Emulator = require './emulator'
GenericClock = require './devices/clock'

program = null
emu = null
code = $ '#code'
paused = false
raw = code.text()

load_program = ->
  program = window.program = new Program
  program.load raw

init_emulator = ->
  emu = window.emu = new Emulator sync: true, max_queue_length: 5
  emu.load_program program
  emu.on_fire dcpu_fire
  attach_clock()
  select_line()

attach_clock = ->
  clock = new GenericClock emu
  clock.on_tick tick
  emu.attach_device clock

clear_selected_line = ->
  code.find('.hilite').removeClass 'hilite'

select_line = ->
  clear_selected_line()
  code.find(".L#{emu.line()-1}").addClass 'hilite'

program_done = ->
  console.log 'Progam done! Resetting.'
  reset()

reset = ->
  paused = false
  unless $('#run_pause').hasClass 'run'
    toggle_run_pause()
  enable_steps()
  console.log 'HALT DEVICES' # XXX
  emu._halt = true
  finalize = ->
    emu.halt_devices()
    emu.reset()
    setTimeout (-> $('#on-fire').fadeOut()), 1000
    select_line()
  setTimeout finalize, 100

dcpu_fire = ->
  $('#on-fire').show()

tick = ->
  ticker = $ '#clock-tick'
  ticker.show()
  ticker.fadeOut()

run = ->
  toggle_run_pause()
  clear_selected_line()
  disable_steps()
  emu.sync = false
  if paused
    emu.resume()
    emu.run()
  else
    emu.run ->
      program_done()
      select_line()

pause = ->
  toggle_run_pause()
  enable_steps()
  emu.pause()
  select_line()
  paused = true

enable_steps = ->
  $('#step,#over').attr 'disabled', false

disable_steps = ->
  $('#step,#over').attr 'disabled', true

toggle_run_pause = ->
  btn = $('#run_pause')
  btn.toggleClass 'run'
  btn.find('i').toggleClass 'hidden'
  btn.toggleClass 'btn-primary'
  btn.toggleClass 'btn-danger'
  if btn.hasClass 'run'
    btn.html btn.html().replace('Stop', 'Run')
  else
    btn.html btn.html().replace('Run', 'Stop')

window.kick_off = ->
  load_program()
  init_emulator()
  console.log 'Emulator ready!'

$('#step').click ->
  return if $(this).attr('disabled')
  emu.sync = true
  emu.step()
  if emu._halt
    program_done()
  select_line()

$('#run_pause').click ->
  if $(this).hasClass 'run'
    run()
  else
    pause()

$('#pause').click ->
  emu.pause()

$('#reset').click ->
  reset()

$('#over').click ->
  return if $(this).attr('disabled')
  emu.step_over()
  select_line()
