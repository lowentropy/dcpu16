require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './adapters/canvas_adapter', (require, module, exports, __dirname, __filename) ->

  module.exports = class CanvasAdapter
    width: 32 * 4
    height: 12 * 8
    
    attach: (@canvas) ->
      @context = @canvas.getContext '2d'
      @data = @context.createImageData @width, @height
    
    draw: (x, y, c) ->
      index = (y * @width + x) * 4
      @data.data[index+0] = c[0]
      @data.data[index+1] = c[1]
      @data.data[index+2] = c[2]
    
    refresh: ->
      @context.putImageData @data, 0, 0