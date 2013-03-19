module.exports = class Api
  hasMp4 = navigator.userAgent.indexOf("AppleWebKit") > -1 and navigator.mimeTypes["video/mp4"]

  constructor: (@config) ->
    @request = """{
                   "network_id": "#{@config.networkId}",
                   "api_key": "#{@config.apiKey}",
                   "device_id": "#{@config.deviceId}",
                   "number_of_screens": 1,
                   "display_area": [
                   {
                     "id": "display-0",
                     "width": #{@config.width},
                     "height": #{@config.height},
                     "supported_media": [
                       "image/gif",
                       "image/jpeg",
                       "image/png" """ + (if hasMp4 then """,
                       "video/mp4",
                       "video/quicktime" """ else "") + """
                     ],
                     "min_duration": null,
                     "max_duration": null,
                     "allow_audio": #{@config.allowAudio}
                   }
                   ],
                   "latitude": null,
                   "longitude": null,
                   "display_time": ~DISPLAY_TIME~
                   "direct_connection": true,
                   "device_attribute": [
                   {
                     "name": "UserAgent",
                     "value": "#{@config.userAgent}"
                   },
                   {
                     "name": "MimeTypes",
                     "value": "#{@config.mimeTypes.join(', ')}"
                   }
                   ]
                 }"""

  fetch: (params) ->
    $.ajax
      type:         'POST'
      url:          "http://#{@config.host}/api/v1/get_ad/json"
      data:         @request.replace(
                      '~DISPLAY_TIME~',
                      "#{Math.floor(new Date().getTime() / 1000)}")

      success:      (data) =>
                      if data.advertisement?
                        params.success(ad) for ad in data.advertisement

      error:        params.error
      dataType:     'json'
      contentType:  'text/json'
