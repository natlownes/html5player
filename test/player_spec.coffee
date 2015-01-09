require './test_case'
{expect} = require 'chai'
sinon    = require 'sinon'
{stub}   = sinon

AdStream = require '../src/ad_stream'
Player   = require '../src/player'


describe 'Player (image)', ->

  beforeEach ->
    @ads    = @injector.getInstance AdStream
    @player = @injector.getInstance Player
    @clock = sinon.useFakeTimers()

  afterEach ->
    @clock.restore()

  context 'when AdStream emits and image advertisement', ->

    it 'should emit ad only after `length_in_seconds` has elapsed', (done) ->
      spy = sinon.spy (ad) ->
        expect(ad.id).to.equal '1234'
        expect(ad.html5player.was_played).to.be.true
        done()

      @player.on 'error', ->
        # seriously confused by why this needs to exist
        # example:  https://github.com/Dakuan/gulp-jest/pull/4
      @player.on 'data', spy
      @player.write(@fixtures.adResponse.advertisement[0])
      @clock.tick(8000)

      expect(spy).to.have.been.called.once


describe 'Player (video)', ->

  beforeEach ->
    @ads    = @injector.getInstance AdStream
    @player = @injector.getInstance Player

  context 'when AdStream emits a played video advertisement', ->

    it 'should emit ad after "ended" event fires on video el', (done) ->
      ad = @fixtures.adResponse.advertisement[0]
      ad.mime_type = 'video/mp4'

      spy = sinon.spy (ad) ->
        expect(ad.id).to.equal '1234'
        expect(ad.mime_type).to.equal 'video/mp4'
        expect(ad.html5player.was_played).to.be.true
        expect(spy).to.have.been.called.once
        done()

      @player.on 'error', ->
      @player.on 'data', spy
      @player.write(ad)

      fire = =>
        event = new window.Event 'ended'
        @player.video.dispatchEvent event
        clearTimeout(timeout)

      timeout = setTimeout fire, 1

  context 'after displaying an ad', ->

    it 'should be available to be read from the stream'
