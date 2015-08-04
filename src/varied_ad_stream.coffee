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

    @lastRequestTime = 0
    @lastSuccessfulRequestTime = 0

  # The "unique" identity (in terms of adjacency) for an advertisement will be
  # its creative id. The VarietyStream will attempt to not show the same ads
  # back to back.
  _identify: (ad) ->
    ad.creative_id

  _next: (callback) ->
    success = (response) =>
      @lastSuccessfulRequestTime = new Date().getTime()
      ads = response?.advertisement or []

      @_log.write name: 'AdStream', message: "Returned #{ads.length} ads"

      if @_config.cacheAssets
        downloads = for ad in ads
          @_download.request(url: ad.asset_url, ttl: assetTTL)
            .then (path) ->
              # Save the original asset url to let Cortex apps use it for
              # reporting purposes. Until we have a better alternative in ad
              # response, asset url is the only sensible piece we can share
              # with end users.
              ad.original_asset_url = ad.asset_url
              # We need to update the asset_url here so it points to the local
              # (cached) location and not S3 or whatever. Typically the
              # asset_url is what is passed to Cortex#submitView / submitVideo.
              ad.asset_url = path

        deferred(downloads...)
          .then ->
            callback(ads)
          .catch ->
            succeeded = (ad for ad, i in ads when not downloads[i].failed)
            callback(succeeded)
          .done()
      else
        callback(ads)

    error = (e) =>
      @_log.write name: 'AdStream', message: "request error #{JSON.stringify(e)}"
      cb = ->
        callback([])
      # error was most likely due to an internet problem. backoff a bit in
      # order not to flood the console with error messages.
      setTimeout cb, 1000

    @lastRequestTime = new Date().getTime()
    @_adRequest.fetch().then(success).catch(error)

module.exports = VariedAdStream
