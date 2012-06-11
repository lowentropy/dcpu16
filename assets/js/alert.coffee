window._alert = (msg, timeout=2000) ->
  $('#alerts').append $('<div class="alert">' + msg + '</div>')
  elem = $('#alerts').find(':last-child')
  setTimeout (-> elem.fadeOut()), timeout