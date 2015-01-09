inject      = require 'honk-di'
{Ajax}      = require './ajax'
Logger      = require './logger'
{Transform} = require('stream')


class ProofOfPlay extends Transform
  @scope: 'SINGLETON'

  http:    inject Ajax
  config:  inject 'config'
  log:     inject Logger

  constructor: ->
    super(objectMode: true)

  expire: (ad) ->
    @log.write name: 'ProofOfPlay', message: 'expiring', meta: ad
    url = ad.expiration_url
    req = @http.request
      type: 'GET'
      url:  url
    req.then (response) -> JSON.parse(response)

  confirm: (ad) ->
    @log.write name: 'ProofOfPlay', message: 'confirming', meta: ad
    url = ad.proof_of_play_url
    req = @http.request
      type: 'POST'
      url:  url
      data: JSON.stringify(display_time: ad.display_time)
    req.then (response) -> JSON.parse(response)

  _transform: (ad, encoding, callback) ->
    if @_wasDisplayed(ad)
      @confirm(ad).then (response) ->
        callback(null, response)
    else
      @expire(ad).then (response) ->
        callback(null, response)

  _wasDisplayed: (ad) ->
    ad.html5player?.was_played


module.exports = ProofOfPlay
