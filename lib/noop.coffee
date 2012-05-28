require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './noop', (require, module, exports, __dirname, __filename) ->

  module.exports = class Noop
    to_bin: -> []
    size: -> 0
    is_op: -> false