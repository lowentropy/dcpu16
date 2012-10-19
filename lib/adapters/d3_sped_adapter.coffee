require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './adapters/d3_sped_adapter', (require, module, exports, __dirname, __filename) ->

  module.exports = class D3SpedAdapter

    constructor: ->
      @reset()

    reset: ->
      @angle = 0

    start_rotating: (right) ->
      # TODO

    stop_rotating: (angle) ->
      @update_angle angle

    update_angle: (angle) ->
      # TODO

    update_vertices: (vertices) ->
      # TODO
