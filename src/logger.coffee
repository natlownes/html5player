inject   = require 'honk-di'


class Logger
  config: inject 'config'

  write: (obj) =>
    if @config.debug
      obj['timestamp'] = @_now()
      console.log JSON.stringify(obj)

  _now: -> Math.floor((new Date()).getTime() / 1000)


module.exports = Logger
