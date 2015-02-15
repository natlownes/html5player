inject      = require 'honk-di'
Logger      = require './logger'
{Download}  = require './ajax'
{Transform} = require('stream')

now = -> (new Date).getTime()

# default ttl is 6 hours:  it's important that this number isn't any shorter
# than the maximum amount of time an ad will sit in the pipeline since there's
# no safeguard to ensure the url isn't expired before it gets to the player
defaultTtl = 6 * 60 * 60 * 1000


class AdCache extends Transform
  config:    inject 'config'
  download:  inject Download
  log:       inject Logger

  constructor: (@ttl=defaultTtl) ->
    super(objectMode: true, highWaterMark: 60)

  _transform: (ad, encoding, callback) ->
    url = ad.asset_url

    @log.write name: 'AdCache', message:
      """
      received #{url}, read length #{@_readableState.buffer.length}
      write length #{@_writableState.buffer.length}
      """

    request = @download.request url: url, ttl: @ttl
    request.then (path) =>
      ad.asset_url = path
      @log.write name: 'AdCache', message:
         "found #{path} for #{ad.asset_url}"
      @push(ad)
      callback()


module.exports = AdCache
