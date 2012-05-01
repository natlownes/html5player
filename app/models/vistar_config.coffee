module.exports = class VistarConfig
  
  constructor: (params) ->
    @networkId = params.networkId
    @apiKey = params.apiKey
    @width = params.width
    @height = params.height
    @deviceId = params.deviceId
    @allowAudio = params.allowAudio
