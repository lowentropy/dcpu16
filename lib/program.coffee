require.define ?= require('./require-define')(module, exports, __dirname, __filename)
require.define './program', (require, module, exports, __dirname, __filename) ->

  Line = require './line'
  path = require 'path'

  module.exports = class Program
  
    constructor: ->
      @filename = '<raw>'
      @labels = {}
      @active_files = {}
    
    name: ->
      if @filename == '<raw>'
        'untitled'
      else
        path.basename @file
  
    load_from_file: (@filename) ->
      @active_files = {}
      @active_files[@name()] = true
      @load @fs().readFileSync(@filename).toString()
  
    fs: ->
      @_fs ?= require 'fs'
  
    load: (@raw) ->
      @split_lines()
      @record_labels()
      @parse_lines()
      @assign_addresses()
      @compile()
    
    watch: (callback) ->
      # TODO
      @watched = true
    
    unwatch: ->
      return unless @watched
      # TODO
      @watched = false
  
    split_lines: ->
      @lines = []
      for line, index in @raw.split "\n"
        @lines.push(new Line this, line, @name(), index+1) if line.length
      # @lines.pop() unless @lines[@lines.length - 1]
  
    record_labels: ->
      labels = []
      for line in @lines
        labels = labels.concat line.labels
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
