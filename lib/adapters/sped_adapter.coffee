require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './adapters/sped_adapter', (require, module, exports, __dirname, __filename) ->

  { Clock, WebGLRenderer, Scene, PerspectiveCamera, Vector3,
    Mesh, LineBasicMaterial, Line, AmbientLight, Geometry, Color
    MeshLambertMaterial, SphereGeometry, AxisHelper, PointLight
  } = THREE

  module.exports = class SpedAdapter

    constructor: (opts={}) ->
      {@width, @height} = opts
      @width ?= 384
      @height ?= 288
      @reset()

    reset: ->

    init: (@container) ->
      @renderer = new WebGLRenderer
      @renderer.setSize @width, @height
      @scene = new Scene
      @build_scene()
      @container.append @renderer.domElement

    build_scene: ->
      @build_camera()
      @build_light()
      # @build_center_sphere()

    build_camera: ->
      @camera = new PerspectiveCamera(75, @width/@height, 0.1, 100)
      @camera.position.set(2, 0, 0)
      @camera.up = new Vector3(0, 0, 1)
      # @camera.position.set 5, 5, 5 # XXX
      @camera.lookAt new Vector3(0, 0, 0)
      @scene.add @camera

    build_light: ->
      @light = new AmbientLight 0xA0A0A0
      @scene.add @light

    build_center_sphere: ->
      material = new MeshLambertMaterial color: 0xFF0000
      geom = new SphereGeometry 0.1, 16, 16
      sphere = new Mesh geom, material
      sphere.position.set 0, 0, 0
      @scene.add sphere

    animate: ->
      @render()

    render: ->
      requestAnimationFrame => @render()
      angle = (@device?.angle() || 0) * Math.PI / 180
      @line.rotation.z = angle if @line
      @renderer.render(@scene, @camera)

    update_vertices: (vertices) ->
      @scene.remove @line if @line
      geom = new Geometry
      material = new LineBasicMaterial
        lineWidth: 1
        vertexColors: true
        # color: 0x00FF00
      for vertex in vertices
        [x, y, z, c] = vertex
        v = new Vector3 x-0.5, y-0.5, z-0.5
        c = new Color c
        geom.vertices.push v
        geom.colors.push c
      @line = new Line geom, material
      @scene.add @line
