require './test_case'
AdCache  = require '../src/ad_cache'
sinon    = require 'sinon'
through2 = require 'through2'
{Ajax}   = require '../src/ajax'
{expect} = require 'chai'


describe 'AdCache', ->

  beforeEach ->
    @http = @injector.getInstance Ajax
    @getAd = =>
      JSON.parse(JSON.stringify(@fixtures.adResponse.advertisement[0]))

  context 'when asset is not cached', ->

    beforeEach ->
      @now   = 142460040000
      @clock = sinon.useFakeTimers(@now)
      @cache = @injector.getInstance AdCache
      URL.createObjectURL.returns('blob:someblob')

    afterEach ->
      @clock.restore()

    it 'should make request with responseType "blob"', (done) ->
      ad = @getAd()
      assetUrl = ad.asset_url
      @http.match url: assetUrl, type: 'GET', (req, resolve) ->
        expect(req.responseType).to.equal 'blob'
        done()

      @cache.write(ad)

    it 'should add to the cache with cachedAt timestamp', (done) ->
      ad = @getAd()
      assetUrl = ad.asset_url
      @http.match url: assetUrl, type: 'GET', (req, resolve) ->
        resolve response: sinon.stub()

      @cache.pipe through2.obj =>
        expect(@cache.store[assetUrl].cachedAt).to.equal @now
        done()

      @cache.write(ad)

    it 'should put dataUrl from URL.createObjectURL in cache', (done) ->
      ad = @getAd()
      assetUrl = ad.asset_url
      @http.match url: assetUrl, type: 'GET', (req, resolve) ->
        resolve response: sinon.stub()

      @cache.pipe through2.obj =>
        expect(@cache.store[assetUrl].dataUrl).to.equal 'blob:someblob'
        done()

      @cache.write(ad)

    it 'should change the `ad.asset_url` to the dataUrl', (done) ->
      ad = @getAd()
      assetUrl = ad.asset_url
      @http.match url: assetUrl, type: 'GET', (req, resolve) ->
        resolve
          size: 2000
          type: 'image/jpeg'

      @cache.pipe through2.obj (adWithDataUrl) ->
        expect(adWithDataUrl.asset_url).to.equal 'blob:someblob'
        done()

      @cache.write(ad)

  context 'when asset is already cached', ->

    beforeEach ->
      @ad = @getAd()
      @assetUrl = @ad.asset_url
      @store = {}
      @store[@assetUrl] =
        cachedAt:     (new Date).getTime()
        lastSeenAt:   (new Date).getTime()
        dataUrl:      'blob:somethingsomething'
        sizeInBytes:  5000
        mimeType:     'image/png'
      @cache = @injector.getInstance AdCache, @store

      @now   = 142460040000
      @clock = sinon.useFakeTimers(@now)

    afterEach ->
      @clock.restore()

    it 'should update the lastSeenAt time of the cached asset', (done) ->
      @cache.pipe through2.obj =>
        cacheEntry = @store[@assetUrl]
        expect(cacheEntry).to.exist
        expect(cacheEntry.lastSeenAt).to.equal @now
        done()

      @cache.write(@ad)

    it 'should emit the ad with the asset_url as the dataUrl', (done) ->
      @cache.pipe through2.obj (adWithDataUrl) ->
        expect(adWithDataUrl.asset_url).to.equal 'blob:somethingsomething'
        done()

      @cache.write(@ad)

  context 'when expire runs', ->

    beforeEach ->
      @clock = sinon.useFakeTimers(1424122265803)
      @store = {}
      # set lastSeenAt to 7 hours ago to see if it will expire
      @store['http://asset.example.com/1.jpg'] =
        lastSeenAt:     (new Date).getTime() - (9 * 60 * 60 * 1000)
        lastSeenAt:     (new Date).getTime() - (7 * 60 * 60 * 1000)
        dataUrl:      'blob://somethingsomething1'
        sizeInBytes:  5000
        mimeType:     'image/png'
      @store['http://asset.example.com/2.webm'] =
        cachedAt:     (new Date).getTime()
        lastSeenAt:     (new Date).getTime() - 1000
        dataUrl:      'blob://somethingsomething2'
        sizeInBytes:  5000
        mimeType:     'video/webm'

      @cache = @injector.getInstance AdCache, @store

    afterEach ->
      @clock.restore()

    it 'should remove expired assets from the store every 15 minutes', ->
      @clock.tick(15 * 60 * 1000)

      expect(@store['http://asset.example.com/1.jpg']).to.not.exist
      expect(@store['http://asset.example.com/2.webm']).to.exist

    context 'and assets should expire', ->

      it 'should call URL.revokeObjectURL with the dataUrl', ->
        @clock.tick(15 * 60 * 1000)
        expect(URL.revokeObjectURL).to.have.been.calledOnce
        expect(URL.revokeObjectURL).to.have.been
          .calledWith 'blob://somethingsomething1'
