VarietyQueue = require './variety_queue'


# A pseudo-stream which can feed input (via a pipe) to a stream which applies
# backpressure. It must implement `_identify` (see VarietyQueue for usage) and
# `_next` to generate a new item.
#
# NOTE: In the case that the `_next` call fails, it still MUST invoke the
# callback with an empty array.
class VarietyStream

  constructor: (@lowWatermark) ->

  _identify: (item) ->
    throw Error('VarietyStream._identify not implemented')

  _next: (callback) ->
    throw Error('VarietyStream._next not implemented')

  # Pipe this stream to another and return that stream. The stream this pipes to
  # should apply some backpressure, or this will not be able to try to pick
  # unique values.
  pipe: (stream) =>
    queue   = new VarietyQueue(@_identify)
    reading = false
    writing = false

    tick = =>
      reading = @_readToQueue reading, queue, ->
        reading = false
        tick()

      writing = @_writeToStream writing, queue, stream, ->
        writing = false
        tick()

    tick()
    return stream

  # If needed, prompt a new read and return the new reading state. If the state
  # is currently reading, this will immediately return true. If teh number of
  # items in the buffer are above the low water mark, it will return false (not
  # reading). Otherwise, it will kick off a new read and set reading to true.
  _readToQueue: (reading, queue, callback) ->
    if reading then return true
    if queue.size() >= @lowWatermark then return false

    @_next (items) =>
      queue.push(it) for it in items
      callback()
    return true

  # If the attached stream is available to be written to, invoke it with the
  # next best value popped from the queue. Invoke the callback once that value
  # has been written.
  _writeToStream: (writing, queue, stream, callback) ->
    if writing then return true

    value = queue.pop()
    unless value? then return false

    stream.write(value, callback)
    return true


module.exports = VarietyStream
