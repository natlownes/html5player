inject   = require 'honk-di'
Deferred = require 'deferred'


now = -> (new Date).getTime()


class Ajax
  @scope: 'singleton'

  constructor: ->
    @ajax = @request.bind(this)

  _request: (options, deferred) ->
    throw new Error('Ajax._request is not implemented')

  request: (options) ->
    if not options? then throw new Error('You must provide options')
    deferred = Deferred()
    @_request(options, deferred)
    deferred.promise.then(options.success, options.error)


class XMLHttpAjax extends Ajax

  _request: (options, deferred) ->
    method = options.type or 'GET'
    url    = options.url

    xhr = new window.XMLHttpRequest()
    xhr.responseType = options.responseType

    xhr.onload = (e) =>
      if xhr.status is 200
        if xhr.responseType is 'blob'
          return deferred.resolve(xhr.response)
        switch options.dataType
          when 'json' then deferred.resolve(JSON.parse(xhr.responseText))
          else deferred.resolve(xhr.responseText)
      else
        deferred.reject(e)

    xhr.open(method, url, true)
    xhr.send(options.data)


sum = (list, acc=0) ->
  if list?.length is 0
    acc
  else
    [head, tail...] = list
    sum(tail, head + acc)


class Download extends Ajax
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
  cache:               inject 'download-cache'
  net:                 window?.Cortex?.net

  constructor: ->
    if @shouldCache()
      @_intervalId = setInterval @expire, @cacheClearInterval
    super()

  expire: =>
    started = now()
    for url, entry of @cache
      diff = (started - entry.lastSeenAt)
      if diff > @ttl
        URL.revokeObjectURL(entry.dataUrl)
        delete @cache[url]

  cacheSizeInBytes: ->
    sum(o.sizeInBytes for url, o of @cache)

  shouldCache: -> not @net?.download?

  _request: (options, deferred) ->
    method = options.type or 'GET'
    ttl    = options.ttl or @ttl
    url    = options.url

    if @net?.download
      # TODO:  Hamza says the api for this will change from returning a promise
      # to the usual node.js (err, callback) -> style.  keep an eye out for that
      # and change this when applicable
      @net.download url, cache: ttl, (path) ->
        deferred.resolve(path)
    else
      if not @cache[url]
        request = @http.request url: url, responseType: 'blob', type: method
        request.then (response) =>
          path = URL.createObjectURL(response)
          @cache[url] =
            cachedAt:     now()
            dataUrl:      path
            lastSeenAt:   now()
            mimeType:     response.type
            sizeInBytes:  response.size
          deferred.resolve(path)
      else
        @cache[url].lastSeenAt = now()
        deferred.resolve(@cache[url].dataUrl)


module.exports = {
  Ajax
  Download
  XMLHttpAjax
}
