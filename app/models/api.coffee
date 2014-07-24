module.exports = class Api
  hasMp4    = navigator.userAgent.indexOf("AppleWebKit") > -1 and navigator.mimeTypes["video/mp4"]
  mimeTypes = (m.type for m in navigator.mimeTypes)

  constructor: (@config) ->
    @request =
      network_id:         @config.networkId
      api_key:            @config.apiKey
      device_id:          @config.deviceId
      venue_id:           @config.venueId
      number_of_screens:  1
      latitude:           @config.latitude
      longitude:          @config.longitude
      direct_connection:  true
      display_time:       null
      display_area: [
        {
          id: "display-0"
          width: @config.width
          height: @config.height
          min_duration: null
          max_duration: null
          allow_audio: @config.allowAudio
          supported_media: @_supportedMedia()
        }
      ]
      device_attribute: [
         {
           name: "UserAgent",
           value: @config.userAgent
         },
         {
           name: "MimeTypes",
           value: mimeTypes.join(', ')
         }
      ]

  _displayTime: ->
    Math.floor(new Date().getTime() / 1000)

  _supportedMedia: ->
    media = [
      "image/gif"
      "image/jpeg"
    ]

    if hasMp4
      media.push("video/mp4")
      media.push("video/quicktime")
    media

  fetch: (params) ->
    @request.display_time = @_displayTime()

    $.ajax
      type:         'POST'
      url:          "http://#{@config.host}/api/v1/get_ad/json"
      data:         JSON.stringify @request
      success:      (data) =>
                      if data.advertisement?
                        params.success(ad) for ad in data.advertisement

      error:        params.error
      dataType:     'json'
      contentType:  'text/json'
