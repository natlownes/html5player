require './test_case'
{expect} = require 'chai'

{requestErrorBody} = require '../src/error'


describe 'requestErrorBody', ->

  it 'should be error message if currentTarget.status is 0', ->
    mockevent =
      currentTarget:
        status: 0
    expect(requestErrorBody(mockevent)).to.equal 'Server or device network down'

  it 'should be the given event if not currentTarget.status', ->
    otherEvent =
      status: 403
      message: 'awwww damn.'

    expect(requestErrorBody(otherEvent)).to.equal otherEvent
