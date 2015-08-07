inject        = require 'honk-di'
Deferred      = require 'deferred'
{Ajax}        = require 'ajax'

Logger   = require './logger'

now = -> (new Date).getTime()


sum = (list, acc=0) ->
  if list?.length is 0
    acc
  else
    [head, tail...] = list
    sum(tail, head + acc)


class Download extends Ajax
  @__honk_clsid = 'Download'
  # "Download" is a class that uses Cortex.net.download (if available) for
  # downloading and caching assets, falling back to using a @store of data uris
  # if Cortex.net doesn't exist
  # https://developer.mozilla.org/en-US/docs/Web/API/URL.createObjectURL
  #
  # default ttl is 6 hours:  it's important that this number isn't any shorter
  # than the maximum amount of time a cached response will sit around waiting to
  # be used, otherwise you'll get a 404 on the blob url
  cacheClearInterval:  15 * 60 * 1000
  http:                inject Ajax
  ttl:                 6 * 60 * 60 * 1000
  _log:                inject Logger

  constructor: ->
    @net    = window?.Cortex?.net
    @_cache = {}
    if @shouldCache()
      @_intervalId = setInterval @expire, @cacheClearInterval
    super()

  expire: =>
    started = now()
    for url, entry of @_cache
      diff = (started - entry.lastSeenAt)
      if diff > @ttl
        URL.revokeObjectURL(entry.dataUrl)
        delete @_cache[url]

  cacheSizeInBytes: ->
    sum(o.sizeInBytes for url, o of @_cache)

  shouldCache: -> not @net?.download?

  _request: (options, deferred) ->
    method = options.type or 'GET'
    ttl    = options.ttl or @ttl
    url    = options.url

    if @net?.download
      opts =
        cache:
          ttl: ttl
          mode: 'normal'
      @net.download url, opts,
        (path) => @_cortexDownloadSuccess(deferred, path)
      ,
        (e) => @_cortexDownloadError(deferred, e)
    else
      if not @_cache[url]
        request = @http.request
          url:              url
          responseType:     'blob'
          type:             method
          withCredentials:  false
        request.then (response) =>
          path = URL.createObjectURL(response)
          @_cache[url] =
            cachedAt:     now()
            dataUrl:      path
            lastSeenAt:   now()
            mimeType:     response.type
            sizeInBytes:  response.size
          deferred.resolve(path)
        .catch (e) =>
          @_log.write
            name: 'Download',
            message: "Local cache error #{JSON.stringify(e)}"
          deferred.reject(e)
      else
        @_cache[url].lastSeenAt = now()
        deferred.resolve(@_cache[url].dataUrl)

  _cortexDownloadSuccess: (deferred, path) ->
    deferred.resolve(path)

  _cortexDownloadError: (deferred, e) =>
    @_log.write
      name: 'Download',
      message: "Cortex cache error #{JSON.stringify(e)}"
    deferred.reject(e)


module.exports = Download
