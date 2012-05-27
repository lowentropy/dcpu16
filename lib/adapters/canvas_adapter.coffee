require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './adapters/canvas_adapter', (require, module, exports, __dirname, __filename) ->

  module.exports = class CanvasAdapter

    scale: 3
    
    constructor: ->
      @width = 32 * 4 * @scale
      @height = 12 * 8 * @scale
    
    attach: (@canvas) ->
      @context = @canvas.getContext '2d'
      @data = @context.createImageData @width, @height
    
    draw: (xb, yb, c) ->
      for i in [0...@scale]
        for j in [0...@scale]
          y = yb * @scale + i
          x = xb * @scale + j
          index = (y * @width + x) * 4
          @data.data[index+0] = c[0]
          @data.data[index+1] = c[1]
          @data.data[index+2] = c[2]
          @data.data[index+3] = 0xff
    
    refresh: ->
      @context.putImageData @data, 0, 0
    
    set_border_color: ([r,g,b]) ->
      $(@canvas).css 'border-color', "rgb(#{r},#{g},#{b})"
