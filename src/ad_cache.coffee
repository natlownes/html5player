inject              = require 'honk-di'
Logger              = require './logger'
net                 = window?.Cortex?.net
{Ajax, XMLHttpAjax} = require './ajax'
{Transform}         = require('stream')

now = -> (new Date).getTime()

# every 15 minutes
cacheClearInterval = 15 * 60 * 1000
# default ttl is 6 hours:  it's important that this number isn't any shorter
# than the maximum amount of time an ad will sit in the pipeline since there's
# no safeguard to ensure the url isn't expired before it gets to the player
defaultTtl         = 6 * 60 * 60 * 1000

sum = (list, acc=0) ->
  if list?.length is 0
    acc
  else
    [head, tail...] = list
    sum(tail, head + acc)


class AdCache extends Transform
  config:          inject 'config'
  http:            inject Ajax
  log:             inject Logger
  sizeInBytes:     0

  constructor: (@store={}, @ttl=defaultTtl) ->
    @sizeInBytes = sum(o.sizeInBytes for url, o of @store)
    setInterval @expire, cacheClearInterval
    super(objectMode: true, highWaterMark: 60)

  fetchPathByAssetURL: (url, cb) ->
    # call callback with either a local path (from Cortex) or an objectURL from
    # URL.createObjectURL
    success = (response) =>
      @store[url] =
        cachedAt:     now()
        lastSeenAt:   now()
        dataUrl:      URL.createObjectURL(response)
        sizeInBytes:  response.size
        mimeType:     response.type

      @sizeInBytes  = @sizeInBytes + response.size
      cb(@store[url].dataUrl)

    if not @store[url]
      request = @http.request
        responseType:  'blob'
        url:           url
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

    if net?.download
      # TODO:  Hamza says the api for this will change from returning a promise
      # to the usual node.js (err, callback) -> style.  keep an eye out for that
      # and change this when applicable
      net.download(url, cache: @ttl).then (path) =>
        ad.asset_url = path
        @push(ad)
        callback()
    else
      @fetchPathByAssetURL url, (path) =>
        ad.asset_url = path
        @log.write name: 'AdCache', message:
          """
          cache entry for #{url} exists?: #{@store[url]?}
          """
        @push(ad)
        callback()


module.exports = AdCache
