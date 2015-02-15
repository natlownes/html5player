Readable  = require('stream').Readable
inject    = require 'honk-di'
AdRequest = require './ad_request'
Logger    = require './logger'


class AdStream extends Readable
  config:          inject 'config'
  log:             inject Logger
  request:         inject AdRequest
  _checkInterval:  100

  constructor: ->
    super(objectMode: true, highWaterMark: (@config.queueSize or 16))
    setInterval @_check, @_checkInterval

  _read: ->
    @log.write name: 'AdStream', message:
      """
      begin _read, readableState buffer len #{@_readableState.buffer.length},
      flowing #{@_readableState.flowing}, reading #{@_readableState.reading},
      len #{@_readableState.length}
      """
    success = (response) =>
      for ad in (response?.advertisement or [])
        @push(ad)
        @log.write name: 'AdStream', message:
          """
          pushed ad #{ad.asset_url},
          readableState buffer len #{@_readableState.buffer.length},
          flowing #{@_readableState.flowing}, reading #{@_readableState.reading},
          len #{@_readableState.length}
          """
    @request.fetch().then(success).done()

  _check: =>
    if @_readableState.length < @_lowWaterMark()
      @log.write name: 'AdStream',
        message: "buffer #{@_readableState.length}, making request"
      @read(0)

  _lowWaterMark: ->
    @_readableState.highWaterMark / 2


module.exports = AdStream
