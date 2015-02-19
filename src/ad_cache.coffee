inject      = require 'honk-di'
Logger      = require './logger'
{Download}  = require './ajax'
{Transform} = require('stream')

now = -> (new Date).getTime()

# every 15 minutes
cacheClearInterval = 15 * 60 * 1000
# default ttl is 6 hours:  it's important that this number isn't any shorter
# than the maximum amount of time an ad will sit in the pipeline since there's
# no safeguard to ensure the url isn't expired before it gets to the player
defaultTtl         = 6 * 60 * 60 * 1000


class AdCache extends Transform
  config:          inject 'config'
  http:            inject Download
  log:             inject Logger

  constructor: (@store={}, @ttl=defaultTtl) ->
    setInterval @expire, cacheClearInterval
    super(objectMode: true, highWaterMark: 60)

  fetchPathByAssetURL: (url, cb) ->
    success = (path) =>
      @store[url] =
        cachedAt:     now()
        lastSeenAt:   now()
        dataUrl:      path
      cb(path)

    if not @store[url]
      request = @http.request url: url, ttl: @ttl
      request.then(success)
    else
      @store[url].lastSeenAt = now()
      cb(@store[url].dataUrl)

  expire: =>
    @log.write name: 'AdCache', message:
      """
      starting clearing store #{JSON.stringify(@store)}
      """
    started = now()
    for url, entry of @store
      diff = (started - entry.lastSeenAt)
      if diff > @ttl
        @log.write name: 'AdCache', message:
          """
          removing cached asset for #{url}, diff #{diff}
          """
        @sizeInBytes = @sizeInBytes - entry.sizeInBytes
        delete @store[url]
        URL.revokeObjectURL(entry.dataUrl)

  _transform: (ad, encoding, callback) ->
    url = ad.asset_url

    @log.write name: 'AdCache', message:
      """
      received #{url}, read length #{@_readableState.buffer.length}
      write length #{@_writableState.buffer.length}
      """

    @fetchPathByAssetURL url, (path) =>
      ad.asset_url = path
      @log.write name: 'AdCache', message:
        """
        cache entry for #{url} exists?: #{@store[url]?}
        """
      @push(ad)
      callback()


module.exports = AdCache
