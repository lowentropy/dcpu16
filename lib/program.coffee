fs = require 'fs'
Line = require './line'

module.exports = class Program
  
  constructor: ->
    @filename = '<raw>'
    @labels = {}
  
  load_from_file: (@filename) ->
    @load fs.readFileSync(@filename).toString()
  
  load: (@raw) ->
    @split_lines()
    @record_labels()
    @parse_lines()
    @assign_addresses()
    @compile()
  
  split_lines: ->
    @lines = []
    for line, index in @raw.split "\n"
      @lines.push(new Line this, line, index+1) if line.length
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
    addr = 0
    for line in @lines
      @bin[addr++] = word for word in line.to_bin()
  
  to_bin: ->
    @bin
