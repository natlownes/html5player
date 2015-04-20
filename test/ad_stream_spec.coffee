require './test_case'
sinon    = require 'sinon'
{expect} = require 'chai'

AdRequest = require '../src/ad_request'
AdStream  = require '../src/ad_stream'
{Ajax}    = require 'ajax'


describe 'AdStream', ->

  beforeEach ->
    @ads  = @injector.getInstance AdStream
    @http = @injector.getInstance Ajax

  it 'should be a readable stream', ->
    expect(@ads).to.respondTo 'read'
    expect(@ads).to.respondTo '_read'

  it 'should inject an AdRequest', ->
    expect(@ads.request).to.be.an.instanceOf AdRequest

  it 'should inject the config', ->
    expect(@ads.config).to.equal @injector.getInstance 'config'

  context 'on successful ad request', ->

    beforeEach ->
      url     = 'http://test.api.vistarmedia.com/api/v1/get_ad/json'
      id      = 0

      @http.match url: url, type: 'POST', (req, promise) =>
        ads = for ad in @fixtures.adResponse.advertisement
          ad = @clone(ad)
          ad.id = "id-#{++id}"
          ad
        promise.resolve advertisement: ads

    it 'should return an ad for each call to `read`', ->
      ad1 = @ads.read()
      ad2 = @ads.read()

      expect(ad1.id).to.equal 'id-1'
      expect(ad2.id).to.equal 'id-2'

    it 'should make another add request when needed', ->
      # read all the ads off the first request.  the AdStream
      # buffer will be empty afterwards
      @ads.read()
      @ads.read()

      ad3 = @ads.read()
      expect(ad3.id).to.equal 'id-3'

  context 'when no ads are returned', ->

    beforeEach ->
      url = 'http://test.api.vistarmedia.com/api/v1/get_ad/json'
      id  = 0
      @http.match url: url, type: 'POST', (req, promise) =>
        promise.resolve advertisement: []

    it.skip 'should call `read` again after 15 seconds', ->
      # TODO:  figure out why fake timers don't work here
      clock = sinon.useFakeTimers()
      spy = sinon.spy @ads, '_check'
      clock.tick(15000)

      expect(spy).to.have.been.called.once

      clock.restore()
