inject      = require 'honk-di'
Logger      = require './logger'
{Ajax}      = require 'ajax'
{Transform} = require('stream')

# PoP stream is unhealthy if there hasn't been any PoP requests in past 3
# minutes.
lastPopRequestTimeThreshold = 3 * 60 * 1000
# PoP stream is unhealthy if there hasn't been any successful PoP requests in
# past 15 minutes.
lastSuccessfulPopRequestTimeThreshold = 15 * 60 * 1000

class ProofOfPlay extends Transform
  http:    inject Ajax
  config:  inject 'config'
  log:     inject Logger

  constructor: ->
    super(objectMode: true, highWaterMark: 100)

    @_isRunning = false
    @_lastPopRequestTime = 0
    @_lastSuccessfulPopRequestTime = 0

  expire: (ad) ->
    @log.write name: 'ProofOfPlay', message: 'expiring', meta: ad
    url = ad.expiration_url
    @http.request
      type:             'GET'
      url:              url
      dataType:         'json'
      withCredentials:  false

  confirm: (ad) ->
    @log.write name: 'ProofOfPlay', message: 'confirming', meta: ad
    url = ad.proof_of_play_url
    @http.request
      type:             'POST'
      url:              url
      dataType:         'json'
      withCredentials:  false
      data:             JSON.stringify(display_time:  ad.display_time)

  _transform: (ad, encoding, callback) ->
    @_isRunning = true
    @_lastPopRequestTime = new Date().getTime()
    write = =>
      @write ad
    if @_wasDisplayed(ad)
      @confirm(ad).then (response) =>
        @_lastSuccessfulPopRequestTime = new Date().getTime()
        @_process(response, callback)
      .catch (e) =>
        callback()
        # According to W3 XHR spec, if the state is UNSENT, OPENED or the error
        # flag is set, status code will be 0. Otherwise, status will be set to
        # HTTP status code. We need to drop the PoP request on server errors.
        if e?.currentTarget?.status == 0
          @log.write name: 'ProofOfPlay', message: 'confirm failed, adding back to the queue.', meta: ad
          setTimeout(write, 5000)
        else
          @log.write name: 'ProofOfPlay', message: 'confirm failed, dropping the request.', meta: ad
    else
      @expire(ad).then (response) =>
        @_lastSuccessfulPopRequestTime = new Date().getTime()
        @_process(response, callback)
      .catch (e) =>
        callback()
        if e?.currentTarget?.status == 0
          @log.write name: 'ProofOfPlay', message: 'expire failed, adding back to the queue.', meta: ad
          setTimeout(write, 5000)
        else
          @log.write name: 'ProofOfPlay', message: 'expire failed, dropping the request.', meta: ad

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

  onHealthCheck: ->
    if not @_isRunning
      return status: true

    now = new Date().getTime()
    threshold = @config.healthCheck?.lastPopRequestTimeThreshold ||
      lastPopRequestTimeThreshold
    if @_lastPopRequestTime + threshold < now
      return {
        status: false
        reason: "No PoP requests in past #{threshold / (60 * 1000)} minutes"
      }

    threshold = @config.healthCheck?.lastSuccessfulPopRequestTimeThreshold ||
      lastSuccessfulPopRequestTimeThreshold
    if @_lastSuccessfulPopRequestTime + threshold < now
      return {
        status: false
        reason: "No successful PoP requests in past #{threshold / (60 * 1000)} minutes"
      }

    return status: true


module.exports = ProofOfPlay
