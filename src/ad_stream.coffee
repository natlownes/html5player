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
    @log.write name: 'AdStream', message: """
      _read called
      readableState buffer len #{@_readableState.buffer.length},
      flowing #{@_readableState.flowing}, reading #{@_readableState.reading},
      len #{@_readableState.length}"""

    success = (response) =>
      ads = response?.advertisement or []
      @log.write name: 'AdStream', message: "returned ad count: #{ads.length}"
      for ad in ads
        @push(ad)

    error = (e) =>
      @log.write name: 'AdStream', message: "request error #{JSON.stringify(e)}"

    @request.fetch().then(success).catch(error).done()

  _check: =>
    if @_readableState.length < @_lowWaterMark()
      @log.write name: 'AdStream',
        message: "buffer #{@_readableState.length}, making request"
      @read(0)

  _lowWaterMark: ->
    @_readableState.highWaterMark / 2


module.exports = AdStream
