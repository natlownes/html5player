inject = require 'honk-di'
{Ajax} = require './ajax'


class AdRequest

  config:     inject 'config'
  http:       inject Ajax
  navigator:  inject 'navigator'

  fetch: ->
    @http.request
      type:      'POST'
      url:       @config.url
      dataType:  'json'
      data:      JSON.stringify(@body())

  body: ->
    # number_of_screens is deprecated
    api_key:            @config.apiKey
    device_attribute:   @_deviceAttribute()
    device_id:          @config.deviceId
    direct_connection:  @config.directConnection
    display_area:       @_displayArea()
    display_time:       Math.floor(new Date().getTime() / 1000)
    latitude:           @config.latitude
    longitude:          @config.longitude
    network_id:         @config.networkId
    venue_id:           @config.venueId
    number_of_screens:  1

  supportedMedia: ->
    # assume that all browsers can at least deal with these
    media  = ['image/gif', 'image/jpeg', 'image/png', 'video/webm']
    for m in @navigator.mimeTypes
      media.push(m.type)
    for type in (@config.mimeTypes or [])
      media.push(type)
    media

  _displayArea: ->
    if not @config.displayArea
      throw new Error('must configure a displayArea list')
    for screen in @config.displayArea
      screen.supported_media = @supportedMedia()
      screen

  _deviceAttribute: -> [
    {
      name: 'UserAgent'
      value: @navigator.userAgent
    }
    {
      name: 'MimeTypes'
      value: @supportedMedia().join(', ')
    }

  ]


module.exports = AdRequest
