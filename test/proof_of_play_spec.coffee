require './test_case'
sinon    = require 'sinon'
{stub}   = sinon
{expect} = require 'chai'

ProofOfPlay = require '../src/proof_of_play'


describe 'ProofOfPlay', ->

  beforeEach ->
    @pop = @injector.getInstance ProofOfPlay

  it 'should expire an advertisement if not html5player.was_played', (done) ->
    ad =
      id: 'some-id'
      expiration_url: 'http://pop.example.com/expire?v=1'
      html5player:
        was_played: false

    @server.when 'GET', 'http://pop.example.com/expire?v=1', =>
      status: 200
      body: JSON.stringify @fixtures.expireResponse
      done()

    @pop.write(ad)

  it 'should pop an advertisement if html5player.was_played', (done) ->
    ad =
      id: 'some-id'
      proof_of_play_url: 'http://pop.example.com/played?v=1'
      html5player:
        was_played: true

    @server.when 'POST', 'http://pop.example.com/played?v=1', =>
      status: 200
      body:   JSON.stringify @fixtures.popResponse
      done()

    @pop.write(ad)

  it 'should emit the PoP response after PoP request success', (done) ->
    ad =
      id: 'some-id'
      proof_of_play_url: 'http://pop.example.com/played?v=1'
      html5player:
        was_played: true

    @server.when 'POST', 'http://pop.example.com/played?v=1', =>
      status: 200
      body:   JSON.stringify @fixtures.popResponse

    @pop.on 'data', (response) =>
      expect(response).to.deep.equal @fixtures.popResponse
      done()

    @pop.write(ad)

  it 'should emit the expire response after expire request success', (done) ->
    ad =
      id: 'some-id'
      expiration_url: 'http://pop.example.com/expire?v=1'
      html5player:
        was_played: false

    @server.when 'GET', 'http://pop.example.com/expire?v=1', =>
      status: 200
      body:   JSON.stringify @fixtures.expireResponse

    @pop.on 'data', (response) =>
      expect(response).to.deep.equal @fixtures.expireResponse
      done()

    @pop.write(ad)

  describe '#expire', ->

    context 'on success', ->

      it 'should return a deferred which will resolve with the response', (done) ->
        ad =
          id: 'some-id'
          expiration_url: 'http://pop.example.com/expire?v=1'
          html5player:
            was_played: false

        @server.when 'GET', 'http://pop.example.com/expire?v=1', =>
          status: 200
          body: JSON.stringify @fixtures.expireResponse

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

      @server.when 'POST', 'http://pop.example.com/pop?v=1', (req) =>
        expect(JSON.parse(req.requestText).display_time).to.equal 1420824124
        done()

      @pop.confirm(ad)

    context 'on success', ->

      it 'should return a deferred which will resolve with the response', (done) ->
        ad =
          id: 'some-id'
          display_time: 140432423
          proof_of_play_url: 'http://pop.example.com/pop?v=1'

        @server.when 'POST', 'http://pop.example.com/pop?v=1', =>
          status: 200
          body: JSON.stringify @fixtures.popResponse

        verify = (response) =>
          expect(response).to.deep.equal @fixtures.popResponse
          done()

        @pop.confirm(ad).then(verify)
