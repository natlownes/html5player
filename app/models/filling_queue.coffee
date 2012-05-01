module.exports = class FillingQueue

  constructor: (@size) ->
    @queue = []
    this.check()

  push: (item) ->
    @queue.push(item)
    this.check()

  pop: ->
    this.check()
    @queue.pop()

  fill: ->
    throw Exception("Must be implemented.")

  check: ->
    if @queue.length < @size
      this.fill()
