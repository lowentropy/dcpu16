require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './adapters/sped_adapter', (require, module, exports, __dirname, __filename) ->

  { Clock, WebGLRenderer, Scene, PerspectiveCamera, Vector3,
    Mesh, LineBasicMaterial, Line, AmbientLight, Geometry, Color
  } = THREE

  module.exports = class SpedAdapter

    constructor: ->
      @reset()

    reset: ->
      @angle = 0

    init: (@container) ->
      @renderer = new WebGLRenderer
      @scene = new Scene
      @build_scene()
      @container.append @scene, @camera

    build_scene: ->
      @build_camera()
      @build_light()

    build_camera: ->
      @camera = new PerspectiveCamera(45, 1, 0.1, 10)
      @camera.position.set(2, 0.5, 0.5)
      @camera.up = new Vector3(0, 0, 1)
      @camera.lookAt new Vector3(0.5, 0.5, 0.5)
      @scene.add @camera

    build_light: ->
      @light = new AmbientLight 0xA0A0A0
      @scene.add @light

    animate: ->
      @render()

    render: ->
      requestAnimationFrame => @render()
      @line.rotation.z = @device?.angle() || 0 if @line
      @renderer.render(@scene, @camera)

    update_vertices: (vertices) ->
      @scene.remove @line if @line
      geom = new Geometry
      material = new LineBasicMaterial
        lineWidth: 1
        vertexColors: true
      for vertex in vertices
        [x, y, z, c] = vertex
        geom.vertices.push(new Vector3 x, y, z)
        geom.colors.push(new Color c)
      @line = new Line geom, material
      @scene.add @line
