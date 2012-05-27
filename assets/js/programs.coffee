files = JSON.parse $('#files').text()

socket = io.connect 'http://localhost:3000'
socket.on 'update_file', (name, content) ->
  files[name] = content
  if name == chosen
    choose_file(name)
    _alert "Reloaded file <strong>#{name}</strong>"

chosen = null

choose_file = (name) ->
  $('.chosen-file').text name
  window.load_program files[name]
  chosen = name

$ ->
  $('#file-choices li').click ->
    name = $(this).text().trim()
    choose_file name
