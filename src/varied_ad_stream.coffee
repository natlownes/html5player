deferred = require 'deferred'
inject   = require 'honk-di'

AdRequest     = require './ad_request'
Download      = require './download'
Logger        = require './logger'
VarietyStream = require './variety_stream'


assetTTL = 6 * 60 * 60 * 1000

# Ad stream is unhealthy if there hasn't been any ad requests in past 3
# minutes.
lastAdRequestTimeThreshold = 3 * 60 * 1000
# Ad stream is unhealthy if there hasn't been any successful ad requests in
# past 15 minutes.
lastSuccessfulAdRequestTimeThreshold = 15 * 60 * 1000

class VariedAdStream extends VarietyStream
  _adRequest:  inject AdRequest
  _config:     inject 'config'
  _download:   inject Download
  _log:        inject Logger

  constructor: ->
    super(@_config.queueSize or 16)

    @_isRunning = false
    @_lastAdRequestTime = 0
    @_lastSuccessfulAdRequestTime = 0

  # The "unique" identity (in terms of adjacency) for an advertisement will be
  # its creative id. The VarietyStream will attempt to not show the same ads
  # back to back.
  _identify: (ad) ->
    ad.creative_id

  _next: (callback) ->
    @_isRunning = true

    success = (response) =>
      @_lastSuccessfulAdRequestTime = new Date().getTime()
      ads = response?.advertisement or []

      @_log.write name: 'AdStream', message: "Returned #{ads.length} ads"

      if @_config.cacheAssets
        downloads = for ad in ads
          @_download.request(url: ad.asset_url, ttl: assetTTL)
            .then (path) ->
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

    @_lastAdRequestTime = new Date().getTime()
    @_adRequest.fetch().then(success).catch(error)

  onHealthCheck: ->
    if not @_isRunning
      return status: true

    now = new Date().getTime()
    threshold = @_config.healthCheck?.lastAdRequestTimeThreshold ||
      lastAdRequestTimeThreshold
    if @_lastAdRequestTime + threshold < now
      return {
        status: false
        reason: "No ad requests in past #{threshold / (60 * 1000)} minutes"
      }

    threshold = @_config.healthCheck?.lastSuccessfulAdRequestTimeThreshold ||
      lastSuccessfulAdRequestTimeThreshold
    if @_lastSuccessfulAdRequestTime + threshold < now
      return {
        status: false
        reason: "No successful ad requests in past #{threshold / (60 * 1000)} minutes"
      }

    return status: true


module.exports = VariedAdStream
