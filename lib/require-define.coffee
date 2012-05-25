if require?.define?
  _img = new Image
  _i = 1
  window.process =
    nextTick: (callback) ->
      _img.onerror = callback
      _img.src = 'data:image/png,' + _i++
      
else
  module.exports = (args...) ->
    return (_name, fn) ->
      fn(require, args...)
