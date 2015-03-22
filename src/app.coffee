inject              = require 'honk-di'

Player              = require './player'
ProofOfPlay         = require './proof_of_play'
VariedAdStream      = require './varied_ad_stream'
{Ajax, XMLHttpAjax} = require './ajax'

defaultConfig = {}
defaultConfig['vistar.api_key']    = '58b68728-11d4-41ed-964a-95dca7b59abd'
defaultConfig['vistar.network_id'] = 'Ex-f6cCtRcydns8mcQqFWQ'
defaultConfig['vistar.device_id']  = 'test-device-id'
defaultConfig['vistar.url']        =
  'http://dev.api.vistarmedia.com/api/v1/get_ad/json'

config = window.Cortex?.getConfig() or defaultConfig


window?.Vistar = ->
  # an example app
  class Binder extends inject.Binder
    configure: ->
      @bind(Ajax).to(XMLHttpAjax)
      @bindConstant('navigator').to window.navigator
      @bindConstant('video').to document.querySelector('.player video')
      @bindConstant('image').to document.querySelector('.player img')
      @bindConstant('download-cache').to {}
      @bindConstant('config').to
        url:               config['vistar.url']
        apiKey:            config['vistar.api_key']
        networkId:         config['vistar.network_id']
        deviceId:          window.Cortex?.player?.id() or config['vistar.device_id']
        venueId:           config['vistar.venue_id']
        width:             1280
        height:            720
        allowAudio:        true
        directConnection:  false
        latitude:          39.9859241
        longitude:         -75.1299363
        queueSize:         10
        debug:             false
        mimeTypes:         ['image/gif', 'image/jpeg', 'image/png', 'video/webm']
        displayArea: [
          {
            id:               'display-0'
            width:            1280
            height:           720
            allow_audio:      false
            cpm_floor_cents:  Number(config['vistar.cpm_floor_cents'] or 0)
          }
        ]

  injector = new inject.Injector(new Binder)

  store  = injector.getInstance 'download-cache'

  ads    = injector.getInstance VariedAdStream
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
    .pipe(player)
    .pipe(pop)
