require './test_case'

sinon       = require 'sinon'
{Transform} = require 'stream'
{expect}    = require 'chai'

VarietyStream = require '../src/variety_stream'


describe 'Variety Pipe', ->

  beforeEach ->
    @next = sinon.stub()
    @stream = new VarietyStream(5)
    @stream._identify = (x) -> x
    @stream._next = @next

  context 'when reading the queue', ->

    context 'when currently reading', ->

      beforeEach ->
        @readState = @stream._readToQueue(true, null, null)

      it 'should leave read state true', ->
        expect(@readState).to.be.true

      it 'should not prompt a read', ->
        expect(@next).to.not.have.been.called

    context 'when above the LWM', ->

      beforeEach ->
        @queue     = size: sinon.stub().returns(10)
        @readState = @stream._readToQueue(false, @queue, null)

      it 'should check the size', ->
        expect(@queue.size).to.have.been.called

      it 'should not prompt a read', ->
        expect(@next).to.not.have.been.called

      it 'should set read state to false', ->
        expect(@readState).to.be.false

    context 'when below LWM', ->

      beforeEach ->
        @queue = size: sinon.stub().returns(3)

      it 'should check the size', ->
        @stream._readToQueue(false, @queue, null)
        expect(@queue.size).to.have.been.called

      it 'should prompt a read', ->
        @stream._readToQueue(false, @queue, null)
        expect(@next).to.have.been.called

      it 'should set read state to true', ->
        rs = @stream._readToQueue(false, @queue, null)
        expect(rs).to.be.true

  context 'when writing to the stream', ->

    beforeEach ->
      @dst = write: sinon.spy()

    context 'when already writing', ->

      beforeEach ->
        @writeState = @stream._writeToStream(true, null, @dst)

      it 'should leave write state true', ->
        expect(@writeState).to.be.true

      it 'should not write', ->
        expect(@dst.write).to.not.have.been.called

    context 'with no value to pop', ->

      beforeEach ->
        @queue = pop: sinon.stub().returns(null)
        @writeState = @stream._writeToStream(false, @queue, @dst)

      it 'should attempt to pop a value', ->
        expect(@queue.pop).to.have.been.called

      it 'should set write state to false', ->
        expect(@writeState).to.be.false

      it 'should not write', ->
        expect(@dst.write).to.not.have.been.called

    context 'with a value to pop', ->
      beforeEach ->
        @queue = pop: sinon.stub().returns('Party time!')
        @writeState = @stream._writeToStream(false, @queue, @dst)

      it 'should transition to writing', ->
        expect(@writeState).to.be.true

      it 'should write the value to the dst stream', ->
        expect(@dst.write).to.have.been.calledWith('Party time!')
