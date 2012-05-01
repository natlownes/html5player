Api = require './api'
AssetBank = require './asset_bank'
AdQueue = require './ad_queue'
PlayQueue = require './play_queue'

module.exports = class VistarPlayer
  
  constructor: (config, $imagePlayer, $videoPlayer) ->
    api = new Api(config)
    assetBank = new AssetBank()
    adQueue = new AdQueue(api, assetBank, 5)
    @playQueue = new PlayQueue(adQueue, 1, $imagePlayer, $videoPlayer)

    $imagePlayer.attr("width", config.width).attr("height", config.height)
    $videoPlayer.attr("width", config.width).attr("height", config.height)

  play: ->
    @playQueue.play()
