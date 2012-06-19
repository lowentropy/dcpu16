#= require ../../lib/require-define
#= require_tree ../../lib
#= require ./alert
#= require ./breakpoints
#= require ./underscore

Program = require './program'
Emulator = require './emulator'
GenericClock = require './devices/clock'
LEM1802 = require './devices/lem1802'
CanvasAdapter = require './adapters/canvas_adapter'

program = null
emu = null
mirror = null
code = $ '#code'
breakpoints = {}
files = JSON.parse $('#files').text()
file = null


state = 'reset'
goto = (name) ->
  return if state == name
  console.log "#{state}: goto #{name}"
  states[state].leave?()
  state = name
  states[state].enter?()
action = (name) ->
  console.log "#{state}: action #{name}"
  states[state][name]?()

states =
  reset:
    enter: -> reset()
    start: -> goto 'running'
    step: -> goto 'paused'; step()
    leave: -> compile_program()
    
  running:
    enter: -> run()
    reset: -> goto 'reset'
    pause: -> goto 'paused'
    leave: -> stop()
    
  paused:
    enter: -> pause()
    reset: -> goto 'reset'
    step: -> step()
    start: -> goto 'running'
  
  done:
    enter: -> done()
    reset: -> goto 'reset'

file_source = (name) -> files[name]

choose_file = (name) ->
  $('.chosen-file').text name
  mirror.setValue files[name]
  file = name
  compile_program()

init_emulator = ->
  emu = window.emu = new Emulator
  emu.on_fire dcpu_fire
  emu.on_done -> goto 'done'
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

selected_line = null
clear_selected_line = ->
  if selected_line
    mirror.setLineClass selected_line, null, null
    selected_line = null

select_line = ->
  clear_selected_line()
  if line = emu.line()
    line--
    selected_line = mirror.setLineClass line, null, 'emu-line'
    # {x, y} = mirror.charCoords {line, ch: 1}
    # mirror.scrollTo x, y

reset = ->
  console.log "reset()"
  emu.pause()
  finalize = ->
    emu.reset()
    enable_step()
    enable_run_pause 'run'
    mirror.setOption 'readOnly', false
    select_line()
    put_out_fire()
  setTimeout finalize, 100

compile_program = ->
  program = window.program = new Program source: file_source
  if file
    program.load_file file
  else
    program.load_raw mirror.getValue()
  emu.load_program program
  select_line()

run = ->
  console.log "run()"
  mirror.setOption 'readOnly', true
  enable_run_pause 'pause'
  clear_selected_line()
  disable_step()
  emu.run()

step = ->
  console.log "step()"
  mirror.setOption 'readOnly', true
  emu.step()
  select_line()

pause = ->
  console.log "pause()"
  enable_run_pause 'run'
  enable_step()
  emu.pause()
  finalize = ->
    select_line()
    emu.call_back()
  setTimeout finalize, 100

done = ->
  console.log "done()"
  emu.call_back()
  disable_run_pause()
  disable_step()
  clear_selected_line()

put_out_fire = ->
  $('#on-fire').hide()

dcpu_fire = ->
  $('#on-fire').show()

enable_step = ->
  $('#step,#over').attr 'disabled', false

disable_step = ->
  $('#step,#over').attr 'disabled', true

disable_run_pause = ->
  $('#run_pause').attr 'disabled', true
  
enable_run_pause = (mode) ->
  btn = $('#run_pause')
  btn.attr 'disabled', false
  if mode == 'run'
    btn.addClass 'run'
    btn.removeClass 'pause'
    btn.html btn.html().replace('Stop', 'Run')
    $('#run-icon').removeClass 'hidden'
    $('#pause-icon').addClass 'hidden'
    btn.addClass 'btn-primary'
    btn.removeClass 'btn-danger'
  else
    btn.addClass 'pause'
    btn.removeClass 'run'
    btn.html btn.html().replace('Run', 'Stop')
    $('#run-icon').addClass 'hidden'
    $('#pause-icon').removeClass 'hidden'
    btn.removeClass 'btn-primary'
    btn.addClass 'btn-danger'
  
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

update_cycles = ->
  emu.on_cycles (tc) ->
    diff = tc - last_cycles
    last_cycles = tc
    $('.total-cycles').text("#{tc} (+#{diff})")

pause_on_breakpoints = ->
  emu.on_breakpoint ->
    action 'pause'

setup_codemirror = ->
  cursor_line = null
  mirror = CodeMirror.fromTextArea $('#code')[0],
    lineNumbers: true
    mode: 'dasm'
    theme: 'ambiance'
    tabSize: 2
    electricChars: false
    autoClearEmptyLines: true
    lineWrapping: true
    matchBrackets: true
    readOnly: false
    onChange: ->
      files[file] = mirror.getValue() if file
    onCursorActivity: ->
      if cursor_line != selected_line
        mirror.setLineClass cursor_line, null, null
      cursor_line = mirror.getLineHandle mirror.getCursor().line
      if cursor_line != selected_line
        mirror.setLineClass cursor_line, null, 'cursor-line'
    onGutterClick: (unused, line) ->
      line = program.breakpoint_line line+1
      return unless line
      index = line.lineno - 1
      info = mirror.lineInfo index
      if info.markerText
        clear_breakpoint line
        mirror.clearMarker index
      else
        set_breakpoint line
        mirror.setMarker index, "<span style=\"color: #900\">●</span> %N%"
  cursor_line = mirror.setLineClass 0, 'cursor-line'

set_breakpoint = (line) ->
  breakpoints[line.addr] = true

clear_breakpoint = (line) ->
  delete breakpoints[line.addr]

window.kick_off = ->
  init_emulator()
  link_registers()
  update_cycles()
  pause_on_breakpoints()
  setup_codemirror()

action_map =
  '#step': 'step'
  '#run_pause.run': 'start'
  '#run_pause.pause': 'pause'
  '#reset': 'reset'

for sel, name of action_map
  do (name) ->
    $(sel).live 'click', ->
      return if $(this).attr 'disabled'
      action name

$ ->
  $('#file-choices li').click ->
    name = $(this).text().trim()
    choose_file name
