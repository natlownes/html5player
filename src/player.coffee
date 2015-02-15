inject      = require 'honk-di'
Logger      = require './logger'
{Transform} = require('stream')


class Player extends Transform

  video:         inject 'video'
  image:         inject 'image'
  config:        inject 'config'
  log:           inject Logger

  _timeoutId:  null
  _currentAd:  null

  constructor: ->
    super(highWaterMark: 0, objectMode: true)
    @video.addEventListener 'ended', @_videoFinished
    @video.addEventListener 'play', =>
      @log.write name: 'Player', message: 'video playing'
      @video.className = ''

  hide: ->
    @video.className = 'hidden'
    @image.className = 'hidden'

  playImage: (advertisement, callback) ->
    @hide()
    duration = advertisement.length_in_milliseconds
    finished = =>
      clearTimeout(@_timeoutId)
      ad = @_setAsPlayed(advertisement, true)
      @log.write name: 'Player', message: 'image stopping'
      callback(null, ad)

    @image.setAttribute 'src', advertisement.asset_url

    @log.write name: 'Player', message: 'image playing'
    @image.className = ''

    @_timeoutId = setTimeout finished, duration

  playVideo: (advertisement, callback) ->
    @hide()
    @video.setAttribute 'src', advertisement.asset_url

  _transform: (advertisement, encoding, callback) ->
    @log.write name: 'Player', message:
      """
      receiving advertisement:
      writable buf length #{@_writableState.buffer.length}"
      readable buf length #{@_readableState.buffer.length}"
      """
    @_currentAd = advertisement
    mimeType    = advertisement.mime_type
    if advertisement.mime_type.match(/^image/)
      @playImage(advertisement, callback)
    else if advertisement.mime_type.match(/^video/)
      @playVideo(advertisement, callback)
    else
      callback(null, @_setAsPlayed(advertisement, false))

  _videoFinished: =>
    clearTimeout(@_timeoutId)
    ad = @_setAsPlayed(@_currentAd, true)
    @log.write name: 'Player', message: 'video stopping'
    @_transformState.afterTransform(null, ad)

  _setAsPlayed: (ad, wasPlayed) ->
    ad?['html5player'] =
      was_played: wasPlayed
    ad


module.exports = Player
