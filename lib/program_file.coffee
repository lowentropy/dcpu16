require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './program_file', (require, module, exports, __dirname, __filename) ->

  module.exports = class ProgramFile
  
    constructor: (@program, @name, @raw) ->
  
    parse_requires: ->
      lines = @raw.split "\n"
      for line in lines
        if m = line.match(/^\s*require\s*([^\s]+)/)
          @require m[1]
      @program.add_file this
    
    require: (name) ->
      name = name + '.dasm' unless /\.dasm$/.test name
      @program.require name
    