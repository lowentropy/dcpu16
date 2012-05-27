fs = require 'fs'
path = require 'path'

base = path.resolve(__dirname + '/../programs')
files = {}
callbacks = []

on_update = (callback) -> callbacks.push callback

append = (prefix, string) ->
  if prefix
    prefix + '/' + string
  else
    string

scan_dir = (root, prefix) ->
  fs.readdir root, (err, files) ->
    for file in files
      scan_file append(root,file), append(prefix,file)

scan_file = (file, prefix) ->
  fs.stat file, (err, stat) ->
    if stat.isDirectory()
      scan_dir file, prefix
    else
      fs.watchFile file, (prev, curr) ->
        return if prev.mtime.getTime() == curr.mtime.getTime()
        load_file file, prefix, ->
          for callback in callbacks
            callback prefix, files[prefix]
      load_file file, prefix

load_file = (file, prefix, callback) ->
  fs.readFile file, 'utf8', (err, content) ->
    files[prefix] = content
    callback?()

scan_dir base, null

module.exports = {files, on_update}
