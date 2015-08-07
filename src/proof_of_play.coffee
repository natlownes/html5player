Logger      = require './logger'
inject      = require 'honk-di'
{Ajax}      = require 'ajax'
{Transform} = require('stream')
{requestErrorBody} = require './error'


class ProofOfPlay extends Transform
  http:    inject Ajax
  config:  inject 'config'
  log:     inject Logger

  constructor: ->
    super(objectMode: true, highWaterMark: 100)

    @lastRequestTime = new Date().getTime()
    @lastSuccessfulRequestTime = new Date().getTime()

  expire: (ad) ->
    url = ad.expiration_url
    req = @http.request
      type:             'GET'
      url:              url
      dataType:         'json'
      withCredentials:  false
    req.then (response) =>
      @log.write
        name:           'ProofOfPlay'
        message:        'expire success'
        advertisement:  ad
        request:
          url: url
        response:
          body:  response
          url:   url
     req.catch (respOrEvent) =>
        @log.write
          name:           'ProofOfPlay'
          message:        'expire failed'
          advertisement:  ad
          request:
            url: url
          response:
            body:  requestErrorBody(respOrEvent)
            url:   url
    req

  confirm: (ad) ->
    url  = ad.proof_of_play_url
    body = JSON.stringify(display_time: ad.display_time)
    req = @http.request
      type:             'POST'
      url:              url
      dataType:         'json'
      withCredentials:  false
      data:             body
    req.then (response) =>
      @log.write
        name:           'ProofOfPlay'
        message:        'confirm success'
        advertisement:  ad
        request:
          url:   url
          body:  body
        response:
          body:  response
          url:   url
    req.catch (respOrEvent) =>
      @log.write
        name:           'ProofOfPlay'
        message:        'confirm failed'
        advertisement:  ad
        request:
          url:   url
          body:  body
        response:
          body:  requestErrorBody(respOrEvent)
          url:   url
    req

  _transform: (ad, encoding, callback) ->
    @lastRequestTime = new Date().getTime()
    write = =>
      @write ad
    if @_wasDisplayed(ad)
      @confirm(ad).then (response) =>
        @lastSuccessfulRequestTime = new Date().getTime()
        @_process(response, callback)
      .catch (e) =>
        callback()
        # According to W3 XHR spec, if the state is UNSENT, OPENED or the error
        # flag is set, status code will be 0. Otherwise, status will be set to
        # HTTP status code. We need to drop the PoP request on server errors.
        if e?.currentTarget?.status == 0
          @log.write
            name:     'ProofOfPlay (requeue)'
            message:  'confirm failed:  adding back to the queue.'
            advertisement:  ad
          setTimeout(write, 5000)
        else
          @log.write
            name:     'ProofOfPlay (drop)'
            message:  'confirm failed: dropping the request.'
            advertisement:  ad
    else
      @expire(ad).then (response) =>
        @lastSuccessfulRequestTime = new Date().getTime()
        @_process(response, callback)
      .catch (e) =>
        callback()
        if e?.currentTarget?.status == 0
          @log.write
            name:      'ProofOfPlay (requeue)'
            message:   'expire failed: adding back to the queue.'
            advertisement:  ad
          setTimeout(write, 5000)
        else
          @log.write
            name:      'ProofOfPlay (drop)'
            message:   'expire failed: dropping the request.'
            advertisement:  ad

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
