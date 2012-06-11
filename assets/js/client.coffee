#= require ../../lib/require-define
#= require_tree ../../lib
#= require ./alert
#= require ./programs
#= require ./breakpoints
#= require ./mode/dcpu

Program = require './program'
Emulator = require './emulator'
GenericClock = require './devices/clock'
LEM1802 = require './devices/lem1802'
CanvasAdapter = require './adapters/canvas_adapter'

program = null
emu = null
code = $ '#code'

state = 'reset'
goto = (name) ->
  states[state].leave?()
  state = name
  states[state].enter?()
action = (name) ->
  states[state].action?()


states =
  reset:
    enter: -> reset()
    start: -> goto 'running'
    step: -> step(); goto 'paused'
    
  running:
    enter: -> run()
    reset: -> goto 'reset'
    pause: -> goto 'paused'
    leave: -> stop()
    
  paused:
    reset: -> goto 'reset'
    step: -> step()
    start: -> goto 'running'
  
  done:
    enter: ->
      disable_steps()
      disable_run_pause()
    reset: -> goto 'reset'


window.load_program = (raw) ->
  reset ->
    code.text raw
    prettyPrint()
    program = window.program = new Program
    program.load raw
    emu.load_program program
    run()

init_emulator = ->
  emu = window.emu = new Emulator sync: true, max_queue_length: 5
  emu.on_fire dcpu_fire
  attach_devices()
  select_line()

attach_devices = ->
  attach_clock()
  attach_monitor()

attach_clock = ->
  emu.attach_device(new GenericClock emu)

attach_monitor = ->
  canvas = $('canvas')[0]
  adapter = new CanvasAdapter
  adapter.attach canvas
  lem = new LEM1802 emu, adapter
  lem.start()
  emu.attach_device lem

clear_selected_line = ->
  code.find('.hilite').removeClass 'hilite'

select_line = ->
  clear_selected_line()
  if line = emu.line()
    li = code.find("li:nth-child(#{emu.line()})")
    li.addClass 'hilite'
    pos = li.position().top
    scr = code.scrollTop()
    dif = pos + scr - code.height() / 2 - 100
    code.scrollTop(dif)

reset = (callback) ->
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
    callback?()
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

run = ->
  toggle_run_pause()
  clear_selected_line()
  disable_steps()
  emu.sync = false
  emu.resume()
  emu.run -> goto 'done'

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

disable_run_pause = ->
  $('#run_pause').attr 'disabled', true
  

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
  init_emulator()
  link_registers()
  emu.on_cycles (tc) ->
    diff = tc - last_cycles
    last_cycles = tc
    $('.total-cycles').text("#{tc} (+#{diff})")
  emu.on_breakpoint -> pause()

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

code.find('li').live 'click', ->
  line = $(this).index() + 1
  addr = program.breakpoint_addr line
  line = program.line_map[addr].lineno
  li = code.find("li:nth-child(#{line})")
  li.toggleClass 'breakpoint'
  emu.set_breakpoint addr, li.hasClass('breakpoint')
