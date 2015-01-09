inject              = require 'honk-di'
AdStream            = require './ad_stream'
{Ajax, XMLHttpAjax} = require './ajax'
Player              = require './player'
ProofOfPlay         = require './proof_of_play'


window?.Vistar = (config) ->
  # an example app
  class Binder extends inject.Binder
    configure: ->
      @bind(Ajax).to(XMLHttpAjax)
      @bindConstant('navigator').to window.navigator
      @bindConstant('video').to document.querySelector('.player video')
      @bindConstant('image').to document.querySelector('.player img')
      @bindConstant('config').to
        url:               'http://dev.api.vistarmedia.com/api/v1/get_ad/json'
        apiKey:            '58b68728-11d4-41ed-964a-95dca7b59abd'
        networkId:         'Ex-f6cCtRcydns8mcQqFWQ'
        debug:             true
        width:             1024
        height:            768
        allowAudio:        true
        directConnection:  false
        deviceId:          'YOUR_DEVICE_ID'
        venueId:           'YOUR_VENUE_ID'
        latitude:          39.9859241
        longitude:         -75.1299363
        queueSize:         12
        mimeTypes:         ['video/webm']
        displayArea: [
          {
            id:               'display-0'
            width:            1024
            height:           768
            allow_audio:      false
            cpm_floor_cents:  90
          }
        ]

  injector = new inject.Injector(new Binder)

  ads    = injector.getInstance AdStream
  player = injector.getInstance Player
  pop    = injector.getInstance ProofOfPlay

  ads.pipe(player).pipe(pop)
