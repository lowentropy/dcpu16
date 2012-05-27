files = JSON.parse $('#files').text()

socket = io.connect 'http://localhost:3000'
socket.on 'update_file', (name, content) ->
  files[name] = content
  choose_file(name) if name == chosen

chosen = null

choose_file = (name) ->
  $('.chosen-file').text name
  window.load_program files[name]
  chosen = name

$ ->
  $('#file-choices li').click ->
    name = $(this).text().trim()
    choose_file name