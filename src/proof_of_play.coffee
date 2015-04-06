inject      = require 'honk-di'
Logger      = require './logger'
{Ajax}      = require './ajax'
{Transform} = require('stream')


class ProofOfPlay extends Transform
  http:    inject Ajax
  config:  inject 'config'
  log:     inject Logger

  constructor: ->
    super(objectMode: true, highWaterMark: 100)

  expire: (ad) ->
    @log.write name: 'ProofOfPlay', message: 'expiring', meta: ad
    url = ad.expiration_url
    @http.request
      type:      'GET'
      url:       url
      dataType:  'json'

  confirm: (ad) ->
    @log.write name: 'ProofOfPlay', message: 'confirming', meta: ad
    url = ad.proof_of_play_url
    @http.request
      type:      'POST'
      url:       url
      dataType:  'json'
      data: JSON.stringify(display_time: ad.display_time)

  _transform: (ad, encoding, callback) ->
    if @_wasDisplayed(ad)
      @confirm(ad).then (response) =>
        @_process(response, callback)
      .catch (err) =>
        @log.write name: 'ProofOfPlay', message: 'confirm failed', meta: ad
        callback()
    else
      @expire(ad).then (response) =>
        @_process(response, callback)
      .catch (err) =>
        @log.write name: 'ProofOfPlay', message: 'expire failed', meta: ad
        callback()

  _wasDisplayed: (ad) ->
    ad.html5player?.was_played

  _process: (response, cb) ->
    # optionally pass PoP response on down the pipe.  if there are no consumers
    # of these stream, drop it on the floor.  This needs to happen because if
    # we fill up our _readableState.buffer to the highWaterMark, we'll stop
    # making PoP requests
    if @_readableState.pipesCount > 0
      cb(null, response)
    else
      cb()


module.exports = ProofOfPlay
