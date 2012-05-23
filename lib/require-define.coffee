_next_tick = ->
  channel = new MessageChannel
  head = tail = {}
  channel.port1.onmessage = ->
    next = head.next
    task = next.task
    head = next
    task()
  return (task) ->
    tail = tail.next = {task}
    channel.port2.postMessage()

if require?.define?
  window.process =
    nextTick: _next_tick()
else
  module.exports = (args...) ->
    return (_name, fn) ->
      fn(require, args...)
