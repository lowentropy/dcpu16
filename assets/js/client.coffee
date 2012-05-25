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
  code.find("li:nth-child(#{emu.line()})").addClass 'hilite'

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
    select_line()
  setTimeout finalize, 100

put_out_fire = ->
  $('#on-fire').hide()

dcpu_fire = ->
  $('#on-fire').show()

tick = ->
  ticker = $ '#clock-tick'
  ticker.show()
  ticker.fadeOut()

run = ->
  put_out_fire()
  toggle_run_pause()
  clear_selected_line()
  disable_steps()
  emu.sync = false
  resume() if paused
  emu.run ->
    program_done()
    select_line()

resume = ->
  emu.resume()
  paused = false
  
step = ->
  put_out_fire()
  emu.sync = true
  resume() if paused
  emu.step()
  if emu._halt
    program_done()
  select_line()

pause = ->
  toggle_run_pause()
  enable_steps()
  paused = true
  emu.pause()
  setTimeout select_line, 100
  # select_line()

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
  step()

$('#run_pause').click ->
  if $(this).hasClass 'run'
    run()
  else
    pause()

$('#reset').click ->
  put_out_fire()
  reset()

$('#over').click ->
  return if $(this).attr('disabled')
  emu.step_over()
  select_line()
