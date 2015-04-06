require './test_case'
sinon    = require 'sinon'
through2 = require 'through2'
{expect} = require 'chai'

ProofOfPlay = require '../src/proof_of_play'
{Ajax}      = require '../src/ajax'


describe 'ProofOfPlay', ->

  beforeEach ->
    @pop  = @injector.getInstance ProofOfPlay
    @http = @injector.getInstance Ajax

  it 'should not fill the _readableState.buffer if not piped to anything', ->
    ad =
      id: 'some-id'
      expiration_url: 'http://pop.example.com/expire?v=1'
      html5player:
        was_played: false

    @http.match url: ad.expiration_url, type: 'GET', (req, resolve) =>
      resolve @fixtures.expireResponse

    processFunc = sinon.spy(@pop, '_process')

    @pop.write(ad)
    @pop.write(ad)
    @pop.write(ad)

    expect(processFunc.callCount).to.equal 3
    expect(@pop._readableState.length).to.equal 0

  it 'should expire an advertisement if not html5player.was_played', (done) ->
    ad =
      id: 'some-id'
      expiration_url: 'http://pop.example.com/expire?v=1'
      html5player:
        was_played: false

    @http.match url: ad.expiration_url, type: 'GET', (req, resolve) =>
      resolve @fixtures.expireResponse
      done()

    @pop.write(ad)

  it 'should pop an advertisement if html5player.was_played', (done) ->
    ad =
      id: 'some-id'
      proof_of_play_url: 'http://pop.example.com/played?v=1'
      html5player:
        was_played: true

    @http.match url: ad.proof_of_play_url, type: 'GET', (req, resolve) =>
      resolve @fixtures.popResponse
      done()

    @pop.write(ad)

  it 'should remove that ad from its internal buffer', (done) ->
    ad =
      id: 'some-id'
      proof_of_play_url: 'http://pop.example.com/played?v=1'
      html5player:
        was_played: true

    verify = =>
      expect(@pop._writableState).to.have.length 0
      done()

    @http.match url: ad.proof_of_play_url, type: 'GET', (req, resolve) =>
      expect(@pop._writableState).to.have.length 1
      resolve({})
      setTimeout verify, 1

    expect(@pop._writableState).to.have.length 0
    @pop.write(ad)

  context 'when a PoP request fails', ->

    beforeEach ->
      @popUrl = 'http://pop.example.com/played?v=2'
      @http.match url: @popUrl, type: 'GET', (req, resolve, reject) =>
        reject()

    it 'should drop the PoP request', (done) ->
      ad =
        id: 'some-id'
        proof_of_play_url: @popUrl
        html5player:
          was_played: true

      verify = =>
        expect(@pop._writableState).to.have.length 0
        done()

      @http.match url: @popUrl, type: 'GET', (req, resolve, reject) =>
        expect(@pop._writableState).to.have.length 1
        reject({})
        setTimeout verify, 1

      expect(@pop._writableState).to.have.length 0
      @pop.write(ad)

  context 'when PoP expire fails', ->

    beforeEach ->
      @expireUrl = 'http://pop.example.com/expire?v=2'
      @http.match url: @expireUrl, type: 'GET', (req, resolve, reject) =>
        reject()

    it 'should drop the PoP request', (done) ->
      ad =
        id: 'some-id'
        expiration_url: @expireUrl
        html5player:
          was_played: false

      verify = =>
        expect(@pop._writableState).to.have.length 0
        done()

      @http.match url: @popUrl, type: 'GET', (req, resolve, reject) =>
        expect(@pop._writableState).to.have.length 1
        reject({})
        setTimeout verify, 1

      expect(@pop._writableState).to.have.length 0
      @pop.write(ad)

  context 'when piped to a consuming stream', ->

    it 'should pipe the PoP response after PoP request success', (done) ->
      ad =
        id: 'some-id'
        proof_of_play_url: 'http://pop.example.com/played?v=1'
        html5player:
          was_played: true

      @http.match url: ad.proof_of_play_url, type: 'GET', (req, resolve) =>
        resolve @fixtures.popResponse

      @pop.pipe through2.obj (response) =>
        expect(response).to.deep.equal @fixtures.popResponse
        done()

      @pop.write(ad)

    it 'should emit the expire response after expire request success', (done) ->
      ad =
        id: 'some-id'
        expiration_url: 'http://pop.example.com/expire?v=1'
        html5player:
          was_played: false

      @http.match url: ad.expiration_url, type: 'GET', (req, resolve) =>
        resolve @fixtures.expireResponse

      @pop.pipe through2.obj (response) =>
        expect(response).to.deep.equal @fixtures.expireResponse
        done()

      @pop.write(ad)

  describe '#expire', ->

    context 'on success', ->

      it 'should return a promise to resolve with the response', (done) ->
        ad =
          id: 'some-id'
          expiration_url: 'http://pop.example.com/expire?v=1'
          html5player:
            was_played: false

        @http.match url: ad.expiration_url, type: 'GET', (req, resolve) =>
          resolve @fixtures.expireResponse

        verify = (response) =>
          expect(response).to.deep.equal @fixtures.expireResponse
          done()

        @pop.expire(ad).then(verify)

  describe '#confirm', ->

    it 'should POST the `display_time`', (done) ->
      ad =
        id: 'some-id'
        display_time: 1420824124
        proof_of_play_url: 'http://pop.example.com/pop?v=1'

      @http.match url: ad.proof_of_play_url, type: 'POST', (req, resolve) =>
        expect(JSON.parse(req.data).display_time).to.equal 1420824124
        resolve @fixtures.popResponse

      @pop.confirm(ad).then (response) ->
        done()

    context 'on success', ->

      it 'should return a deferred which will resolve with the response', (done) ->
        ad =
          id: 'some-id'
          display_time: 140432423
          proof_of_play_url: 'http://pop.example.com/pop?v=1'

        @http.match url: ad.proof_of_play_url, type: 'GET', (req, resolve) =>
          resolve @fixtures.popResponse

        verify = (response) =>
          expect(response).to.deep.equal @fixtures.popResponse
          done()

        @pop.confirm(ad).then(verify)

