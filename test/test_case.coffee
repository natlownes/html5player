require './test_dom'
inject = require 'honk-di'
chai   = require 'chai'

{Ajax, XMLHttpAjax} = require '../src/ajax'

chai.use(require('sinon-chai'))


beforeEach ->
  class Binder extends inject.Binder
    configure: ->
      @bind(Ajax).to(XMLHttpAjax)
      @bindConstant('navigator').to
        mimeTypes: [
          type: 'text/x-navigator-mime-type'
        ]
        userAgent: "AppleWebKit"
      @bindConstant('video').to document.querySelector('.player video')
      @bindConstant('image').to document.querySelector('.player img')
      @bindConstant('config').to
        url:               'http://test.api.vistarmedia.com/api/v1/get_ad/json'
        apiKey:            'YOUR_API_KEY'
        networkId:         'YOUR_NETWORK_ID'
        width:             1280
        height:            720
        allowAudio:        true
        directConnection:  false
        deviceId:          'YOUR_DEVICE_ID'
        venueId:           'YOUR_VENUE_ID'
        latitude:          39.9859241
        longitude:         -75.1299363
        queueSize:         32
        mimeTypes:         ['text/x-injected-test-value']
        displayArea: [
          {
            id:            'display-0'
            width:         1280
            height:        720
            min_duration:  null
            max_duration:  null
            allow_audio:   true
          }
        ]

  @injector = new inject.Injector(new Binder)
  @fixtures =
    expireResponse:
      impressions:  0.0
      media_cost:   0
      spots:        0
      errors:       0
      expires:      1
    popResponse:
      impressions:  1.0
      media_cost:   213812903821
      errors:       0
      expires:      0
    adResponse:
      advertisement: [
        {
          id:                      '1234'
          proof_of_play_url:       'http://pop.example.com/pop?ls=1'
          expiration_url:          'http://pop.example.com/v1/expire?ls=1'
          order_id:                ''
          display_time:            1420577949
          lease_expiry:            1420664349
          display_area_id:         'display-0'
          creative_id:             '4f054d6b'
          asset_id:                '1b142408'
          asset_url:               'https://assets.example.com/ad1.jpg'
          width:                   936
          height:                  264
          mime_type:               'image/jpeg'
          length_in_seconds:       8
          length_in_milliseconds:  8000
          campaign_id:             2607205161
          creative_category:       '10013'
        },
        {
          id:                      '5432'
          proof_of_play_url:       'http://pop.example.com/pop?ls=2'
          expiration_url:          'http://pop.example.com/v1/expire?ls=2'
          order_id:                ''
          display_time:            1420577949
          lease_expiry:            1420664349
          display_area_id:         'display-0'
          creative_id:             '4f054d6b'
          asset_id:                '1b142408'
          asset_url:               'https://assets.example.com/ad2.jpg'
          width:                   936
          height:                  264
          mime_type:               'image/jpeg'
          length_in_seconds:       8
          length_in_milliseconds:  8000
          campaign_id:             2607205161
          creative_category:       '10013'
        },
      ]

afterEach ->
  @server.stop()
