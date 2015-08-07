inject   = require 'honk-di'


class Logger
  config: inject 'config'

  write: (obj) =>
    if @config.debug
      obj['timestamp'] = @now()
      console.log JSON.stringify(obj)

  now: -> Math.floor((new Date()).getTime() / 1000)


module.exports = Logger
