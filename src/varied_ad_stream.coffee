deferred = require 'deferred'
inject   = require 'honk-di'

AdRequest     = require './ad_request'
Download      = require './download'
Logger        = require './logger'
VarietyStream = require './variety_stream'


assetTTL = 6 * 60 * 60 * 1000


class VariedAdStream extends VarietyStream
  _adRequest:  inject AdRequest
  _config:     inject 'config'
  _download:   inject Download
  _log:        inject Logger

  constructor: ->
    super(@_config.queueSize or 16)

  # The "unique" identity (in terms of adjacency) for an advertisement will be
  # its creative id. The VarietyStream will attempt to not show the same ads
  # back to back.
  _identify: (ad) ->
    ad.creative_id

  _next: (callback) ->

    success = (response) =>
      ads = response?.advertisement or []

      @_log.write name: 'AdStream', message: "Returned #{ads.length} ads"

      if @_config.cacheAssets
        downloads = for ad in ads
          @_download.request url: ad.asset_url, ttl: assetTTL

        deferred(downloads)
          .then -> callback(ads)
          .catch -> callback([])
      else
        callback(ads)

    error = (e) =>
      @_log.write name: 'AdStream', message: "request error #{JSON.stringify(e)}"
      cb = ->
        callback([])
      # error was most likely due to an internet problem. backoff a bit in
      # order not to flood the console with error messages.
      setTimeout cb, 1000

    @_adRequest.fetch().then(success).catch(error)


module.exports = VariedAdStream
