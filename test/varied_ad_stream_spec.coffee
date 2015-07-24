require './test_case'
Deferred = require 'deferred'
sinon    = require 'sinon'
{expect} = require 'chai'

VariedAdStream  = require '../src/varied_ad_stream'


describe 'VariedAdStream', ->

  beforeEach ->
    @sandbox = sinon.sandbox.create()
    @stream  = @injector.getInstance VariedAdStream
    @sandbox.useFakeTimers()

  afterEach ->
    @sandbox.restore()

  describe '_next', ->

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
      @sandbox.clock.tick(3000)
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

    context 'when caching assets', ->

      it 'should set asset_url to the path _download.request resolves with', ->
        i = 0
        @sandbox.stub @stream._adRequest, 'fetch', =>
          d = Deferred()
          d.resolve(@fixtures.adResponse)
          d.promise
        @sandbox.stub @stream._download, 'request', (obj) ->
          d = Deferred()
          d.resolve("file:///tmp/local/path-#{++i}.jpg")
          d.promise

        cb = sinon.spy()
        @stream._next cb
        @sandbox.clock.tick(1000)

        expect(cb).to.have.been.calledOnce

        [ads] = cb.lastCall.args
        expect(ads).to.have.length 2
        [first, second] = ads
        expect(first.asset_url).to.equal 'file:///tmp/local/path-1.jpg'
        expect(second.asset_url).to.equal 'file:///tmp/local/path-2.jpg'

      it 'should call with empty array if all cache calls fail', ->
        @sandbox.stub @stream._adRequest, 'fetch', =>
          d = Deferred()
          d.resolve(@fixtures.adResponse)
          d.promise
        @sandbox.stub @stream._download, 'request', (obj) ->
          d = Deferred()
          d.reject(new Error('terrible error'))
          d.promise

        cb = sinon.spy()
        @stream._next cb
        @sandbox.clock.tick(1000)

        expect(cb).to.have.been.calledOnce

        [ads] = cb.lastCall.args
        expect(ads).to.have.length 0

      it 'should call callback with all ads if all cache calls succeed', ->
        i = 0
        @sandbox.stub @stream._adRequest, 'fetch', =>
          d = Deferred()
          d.resolve(@fixtures.adResponse)
          d.promise
        @sandbox.stub @stream._download, 'request', (obj) ->
          d = Deferred()
          d.resolve("file:///tmp/local/path-#{++i}.jpg")
          d.promise

        cb = sinon.spy()
        @stream._next cb
        @sandbox.clock.tick(1000)

        expect(cb).to.have.been.calledOnce

        [ads] = cb.lastCall.args
        expect(ads).to.have.length 2

      context 'when only *some* asset_url downloads succeed', ->

        it 'should call with only ads which succeeded', ->
          i = 0
          @sandbox.stub @stream._adRequest, 'fetch', =>
            d = Deferred()
            d.resolve(@fixtures.adResponse)
            d.promise
          @sandbox.stub @stream._download, 'request', (obj) ->
            d = Deferred()
            if i is 0
              d.resolve("file:///tmp/local/path-#{++i}.jpg")
            if i is 1
              d.reject(new Error('terrible error'))
            d.promise

          cb = sinon.spy()
          @stream._next cb
          @sandbox.clock.tick(1000)

          expect(cb).to.have.been.calledOnce

          [ads] = cb.lastCall.args
          expect(ads).to.have.length 1
          [first] = ads
          expect(first.asset_url).to.equal 'file:///tmp/local/path-1.jpg'
