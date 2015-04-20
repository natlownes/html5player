require './test_case'
AdCache  = require '../src/ad_cache'
sinon    = require 'sinon'
through2 = require 'through2'
{Ajax}   = require 'ajax'
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

    it 'should change the `ad.asset_url` to the dataUrl', (done) ->
      ad = @getAd()
      assetUrl = ad.asset_url
      @http.match url: assetUrl, type: 'GET', (req, promise) ->
        promise.resolve
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
      @store = @injector.getInstance 'download-cache'
      @store[@assetUrl] =
        cachedAt:     (new Date).getTime()
        lastSeenAt:   (new Date).getTime()
        dataUrl:      'blob:alreadygotit'
        sizeInBytes:  5000
        mimeType:     'image/png'
      @cache = @injector.getInstance AdCache

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
        expect(adWithDataUrl.asset_url).to.equal 'blob:alreadygotit'
        done()

      @cache.write(@ad)
