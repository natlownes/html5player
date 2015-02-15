inject              = require 'honk-di'
AdCache             = require './ad_cache'
AdStream            = require './ad_stream'
Player              = require './player'
ProofOfPlay         = require './proof_of_play'
{Ajax, XMLHttpAjax} = require './ajax'


window?.Vistar = (config) ->
  # an example app
  class Binder extends inject.Binder
    configure: ->
      @bind(Ajax).to(XMLHttpAjax)
      @bindConstant('navigator').to window.navigator
      @bindConstant('video').to document.querySelector('.player video')
      @bindConstant('image').to document.querySelector('.player img')
      @bindConstant('download-cache').to {}
      @bindConstant('config').to
        url:               'http://dev.api.vistarmedia.com/api/v1/get_ad/json'
        apiKey:            '58b68728-11d4-41ed-964a-95dca7b59abd'
        networkId:         'Ex-f6cCtRcydns8mcQqFWQ'
        width:             1280
        height:            720
        allowAudio:        true
        directConnection:  false
        deviceId:          'YOUR_DEVICE_ID'
        venueId:           'YOUR_VENUE_ID'
        latitude:          39.9859241
        longitude:         -75.1299363
        queueSize:         10
        displayArea: [
          {
            id:               'display-0'
            width:             1280
            height:            720
            allow_audio:      false
            cpm_floor_cents:  90
          }
        ]

  injector = new inject.Injector(new Binder)

  store  = injector.getInstance 'download-cache'

  ads    = injector.getInstance AdStream
  cache  = injector.getInstance AdCache
  player = injector.getInstance Player
  pop    = injector.getInstance ProofOfPlay

  # this exists only so one can inspect the different components while it's
  # running
  window.__vistarplayer =
    ads:     ads
    cache:   cache
    player:  player
    pop:     pop
    store:   store

  ads
    .pipe(cache)
    .pipe(player)
    .pipe(pop)
