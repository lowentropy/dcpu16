unless require?.define?
  module.exports = (args...) ->
    return (_name, fn) ->
      fn(require, args...)
