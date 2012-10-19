require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './program', (require, module, exports, __dirname, __filename) ->

  Line = require './line'
  path = require 'path'
  ProgramFile = require './program_file'
  _ = require 'underscore'

  module.exports = class Program

    constructor: (opts = {}) ->
      @labels = {}
      @_main = null
      @_file_map = {}
      @_files = []
      @_source = opts.source

    load_file: (name) ->
      @load_raw @read_file(name), name

    load_raw: (raw, @name='<raw>') ->
      @_main = new ProgramFile this, @name, raw
      @_main.parse_requires()
      @load()

    read_file: (name) ->
      raw = @_source name
      throw new Error "Can't find file: #{name}" unless raw
      raw

    add_file: (file) ->
      @_files.push file

    file: (name) ->
      @_file_map[name]

    require: (name) ->
      return if @_file_map[name]
      raw = @read_file name
      file = new ProgramFile this, name, raw
      @_file_map[name] = file
      file.parse_requires()

    fs: ->
      @_fs ?= require 'fs'

    load: ->
      @split_lines()
      @record_labels()
      @parse_lines()
      @assign_addresses()
      @compile()

    split_lines: ->
      @lines = []
      for file in @_files
        lines = for line, index in file.raw.split "\n"
          line = line.trim()
          if line.length
            new Line this, line, file.name, index+1
          else
            Line.empty this, file.name, index+1
        @lines.push line for line in lines

    breakpoint_line: (num) ->
      line = @lines[num - 1]
      index = line.lineno - 1
      while line && !line.is_op()
        line = @lines[++index]
      line

    record_labels: ->
      labels = []
      for line in @lines
        labels.push label for label in line.labels
        continue if line.empty()
        @labels[label] = line for label in labels
        labels = []
      @end_labels = labels

    has_label: (label) ->
      @labels[label]?

    resolve_label: (label) ->
      @labels[label]?.addr ? throw new Error "Unknown label: #{label}"

    parse_lines: ->
      line.parse() for line in @lines

    assign_addresses: ->
      addr = 0
      for line in @lines
        line.set_addr addr
        addr += line.size()
      @size = addr
      for label in @end_labels
        @labels[label] = {addr: @size}

    compile: ->
      @bin = (0 for i in [1..@size])
      @line_map = (0 for i in [1..@size])
      addr = 0
      for line in @lines
        for word in line.to_bin()
          @bin[addr] = word
          @line_map[addr] = line
          addr++

    to_bin: ->
      @bin
