Readable  = require('stream').Readable
inject    = require 'honk-di'
AdRequest = require './ad_request'
Logger    = require './logger'


class AdStream extends Readable
  @scope: 'SINGLETON'

  config:          inject 'config'
  log:             inject Logger
  request:         inject AdRequest
  _checkInterval:  100

  constructor: ->
    super(objectMode: true, highWaterMark: (@config.queueSize or 16))
    setInterval @_check, @_checkInterval

  _read: ->
    @log.write name: 'AdStream', message:
      "begin read, buf length #{@_readableState.buffer.length}"
    success = (response) ->
      for ad in (response?.advertisement or [])
        @push(ad)
    @request.fetch().then(success.bind(this)).done()

  _check: =>
    if @_readableState.buffer.length is 0
      @log.write name: 'AdStream', message: 'buffer empty, initiating read'
      @read()


module.exports = AdStream
