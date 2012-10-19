require.define ?= require('../require-define')(module, exports, __dirname, __filename)
require.define './devices/sped3', (require, module, exports, __dirname, __filename) ->

  module.exports = class SPED3

    name: 'Mackapar Suspended Particle Exciter Display, Rev 3 (SPED-3)'
    hardware_id: 0x7349f615
    version_id: 0x0003
    manufacturer_id: 0x1c6c8b36

    base_width: 2

    constructor: (@emu, @adapter) ->
      @reset()

    reset: ->
      @address = null
      @target_angle = 0
      @adapter?.reset()

    start: ->

    send_interrupt: ->
      switch @emu.a.get()
        when 0 then @poll()
        when 1 then @map_region()
        when 2 then @set_rotation()

    poll: ->
      state = if !@address?
        0
      else if @rotating
        2
      else
        1
      @emu.b.set state
      @emu.c.set(if @broken then 0xffff else 0)

    map_region: ->
      @clear_mem_trigger()
      @address = @emu.x.get()
      @set_mem_trigger()
      @num_vertices = @emu.y.get()
      @update_vertices()

    set_rotation: ->
      angle = @real_angle()
      @target_angle = @emu.x.get() % 360
      @rotate_to_target angle

    real_angle: ->
      if @rotating
        da = ((new Date) - @base_time) * 0.05
        da = -da unless @right
        (@start_angle + da) % 360
      else
        @target_angle

    rotate_to_target: (@start_angle) ->
      @rotating = true
      clearTimeout @rotate_timer
      @right = (@start_angle < @target_angle)
      diff = Math.abs(@target_angle - @start_angle)
      if diff > 180
        @right = !@right
        diff = 360 - diff
      @base_time = new Date
      @ttr = diff / 50
      @adapter.start_rotating @right
      @rotate_timer = setTimeout (=> @finish_rotation()), (@ttr * 1000)

    finish_rotation: ->
      @rotating = false
      @adapter.stop_rotating @target_angle

    update_vertices: ->
      vertices = []
      addr = @address
      for i in [0...@num_vertices]
        w1 = @emu.mem_get addr++
        w2 = @emu.mem_get addr++
        vertices.push @parse_vertex(w1, w2)
      @adapter.update_vertices vertices

    clear_mem_trigger: ->
      @emu.remove_mem_trigger @trigger

    set_mem_trigger: ->
      @trigger = @emu.mem_trigger @address, (@address + @num_vertices * 2), => @update_vertices()

    parse_vertex: (w1, w2) ->
      x = w1 & 0xFF
      y = (w1 >> 8) & 0xFF
      z = w2 & 0xFF
      c = (w2 >> 8) & 3
      i = (w2 >> 10) & 1
      width = (i + 1) * @base_width
      color = switch c
        when 0 then 0x000000
        when 1 then 0xFF0000
        when 2 then 0x00FF00
        when 3 then 0x0000FF
      [x, y, z, color, width]

    pause: ->
    resume: ->
    halt: ->
