Deferred = require 'deferred'


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
    if options.responseType
      xhr.responseType = options.responseType

    xhr.onload = (e) =>
      if xhr.status is 200
        if options.responseType == 'blob'
          return deferred.resolve(xhr.response)
        switch options.dataType
          when 'json' then deferred.resolve(JSON.parse(xhr.responseText))
          else deferred.resolve(xhr.responseText)
      else
        deferred.reject(e)

    xhr.open(method, url, true)
    xhr.send(options.data)


module.exports = {Ajax, XMLHttpAjax}
