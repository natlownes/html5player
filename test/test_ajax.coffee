{Ajax} = require '../src/ajax'


class TestAjax extends Ajax

  constructor: ->
    super
    @_handlers = []

  _request: (options, deferred) ->
    found = false
    for [match, handler] in @_handlers
      for k, v of match
        found = options[k] is v
        if not found
          break

      if found
        handler(options, deferred.resolve, deferred.reject)
        break

    if not found
      message = "#{options.type} #{options.url} not found"
      deferred.reject(status: 404, message: message)

  match: (match, handler) ->
    @_handlers.push([match, handler])


module.exports = TestAjax
