#= require ../../lib/require-define
#= require_tree ../../lib

Program = require './program'
Emulator = require './emulator'
GenericClock = require './devices/clock'
LEM1802 = require './devices/lem1802'
CanvasAdapter = require './adapters/canvas_adapter'

program = null
emu = null
code = $ '#code'
paused = false
raw = code.text()
last_cycles = 0
run_cycle_start = 0
run_time = new Date

load_program = ->
  program = window.program = new Program
  program.load raw

init_emulator = ->
  emu = window.emu = new Emulator sync: true, max_queue_length: 5
  emu.load_program program
  emu.on_fire dcpu_fire
  attach_devices()
  select_line()

attach_devices = ->
  attach_clock()
  # attach_monitor()

attach_clock = ->
  clock = new GenericClock emu
  clock.on_tick tick
  emu.attach_device clock

attach_monitor = ->
  canvas = $('canvas')[0]
  adapter = new CanvasAdapter
  adapter.attach canvas
  lem = new LEM1802 emu, adapter
  emu.attach_device lem

clear_selected_line = ->
  code.find('.hilite').removeClass 'hilite'

select_line = ->
  clear_selected_line()
  if line = emu.line()
    code.find("li:nth-child(#{emu.line()})").addClass 'hilite'

program_done = ->
  console.log 'Progam done! Resetting.'
  reset()

reset = ->
  was_paused = paused
  paused = false
  last_cycles = 0
  unless $('#run_pause').hasClass 'run'
    toggle_run_pause()
  enable_steps()
  emu._halt = true
  finalize = ->
    emu.halt_devices()
    emu.reset()
    select_line()
    emu.call_back()
    estimate_speed() unless was_paused
  setTimeout finalize, 100

estimate_speed = ->
  cycles = last_cycles - run_cycle_start
  ms = new Date - run_time
  khz = Math.round(cycles / ms)
  console.log "est speed: #{khz}kHz"

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
  run_cycle_start = last_cycles
  run_time = new Date
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
  emu.call_back()
  if emu._halt
    program_done()
  select_line()

pause = ->
  toggle_run_pause()
  enable_steps()
  paused = true
  emu.pause()
  finalize = ->
    select_line()
    emu.call_back()
    estimate_speed()
  setTimeout finalize, 100
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

link_registers = ->
  $('.reg-val').each ->
    elem = $(this)
    register = elem.attr('data-register').toLowerCase()
    emu[register].on_set (value) ->
      elem.text hex(value)

hex = (value) ->
  pad_left(value.toString(16), 4, '0').toUpperCase()

pad_left = (str, len, pad) ->
  until str.length >= len
    str = pad + str
  str

window.kick_off = ->
  load_program()
  init_emulator()
  link_registers()
  emu.on_cycles (tc) ->
    diff = tc - last_cycles
    last_cycles = tc
    $('.total-cycles').text("#{tc} (+#{diff})")
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
