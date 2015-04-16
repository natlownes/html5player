require './test_case'
Deferred = require 'deferred'
sinon    = require 'sinon'
through2 = require 'through2'
{expect} = require 'chai'

VariedAdStream  = require '../src/varied_ad_stream'
AdRequest       = require '../src/ad_request'
{Ajax}          = require '../src/ajax'


describe 'VariedAdStream', ->

  beforeEach ->
    @stream = @injector.getInstance VariedAdStream
    @adRequest = @injector.getInstance AdRequest
    @http = @injector.getInstance Ajax

  describe '_next', ->
    beforeEach ->
      @clock = sinon.useFakeTimers()

    afterEach ->
      @clock.restore()

    it 'should make an ad request', ->
      fetch = sinon.stub @stream._adRequest, 'fetch', ->
        d = Deferred()
        d.resolve()
        d.promise

      @stream._next(->)

      expect(fetch).to.have.been.calledOnce

    it 'should delay the callback on error', ->
      fetch = sinon.stub @stream._adRequest, 'fetch', ->
        d = Deferred()
        d.reject()
        d.promise

      cb = sinon.stub()
      @stream._next cb
      expect(cb).to.not.have.been.called
      @clock.tick(3000)
      expect(cb).to.have.been.calledOnce

    it 'should cache assets', ->
      fetch = sinon.stub @stream._adRequest, 'fetch', =>
        d = Deferred()
        d.resolve(@fixtures.adResponse)
        d.promise

      download = sinon.spy @stream._download, 'request'

      cb = sinon.stub()
      @stream._next cb
      expect(cb).to.have.been.calledOnce
      expect(download).to.have.been.calledTwice

    it 'should not cache assets if cacheAssets is false', ->
      fetch = sinon.stub @stream._adRequest, 'fetch', =>
        d = Deferred()
        d.resolve(@fixtures.adResponse)
        d.promise

      download = sinon.spy @stream._download, 'request'

      cb = sinon.stub()
      @stream._config.cacheAssets = false
      @stream._next cb
      expect(cb).to.have.been.calledOnce
      expect(cb).to.have.been.calledWith @fixtures.adResponse.advertisement
      expect(download).to.not.have.been.called
