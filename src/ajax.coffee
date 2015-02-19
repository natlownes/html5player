inject   = require 'honk-di'
Deferred = require 'deferred'
net      = window?.Cortex?.net


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


class Download extends Ajax
  ttl: 6 * 60 * 60 * 1000

  http: inject Ajax
  store: {}

  constructor: ->
    super()

  _request: (options, deferred) ->
    # deferred will resolve with a local path if running on Cortex
    #
    # otherwise it will return an object url representing the resource that was
    # requested
    # https://developer.mozilla.org/en-US/docs/Web/API/URL.createObjectURL
    #
    # these object urls should be expired at some point using
    # URL.revokeObjectURL, so keep track of them somewhere
    method = options.type or 'GET'
    ttl    = options.ttl or @ttl
    url    = options.url

    if net?.download
      # TODO:  Hamza says the api for this will change from returning a promise
      # to the usual node.js (err, callback) -> style.  keep an eye out for that
      # and change this when applicable
      net.download(url, cache: ttl).then (path) =>
        deferred.resolve(path)
    else
      request = @http.request url: url, responseType: 'blob', type: method
      request.then (response) ->
        path = URL.createObjectURL(response)
        deferred.resolve(path)


module.exports = {
  Ajax
  Download
  XMLHttpAjax
}
