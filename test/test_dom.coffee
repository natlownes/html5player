{stub}       = require 'sinon'

_initDocument = ->
  domino = require 'domino'
  Window = require 'domino/lib/Window'
  Node   = require 'domino/lib/Node'

  global.document or= domino.createDocument()
  window = new Window(global.document)

  global.window     = window
  global.navigator  = window.navigator

  global.Blob                 = stub()
  global.URL                  = stub()
  global.URL.createObjectURL  = stub()
  global.URL.revokeObjectURL  = stub()

  player = document.createElement('div')
  video  = document.createElement('video')
  image  = document.createElement('img')

  player.appendChild(video)
  player.appendChild(image)
  player.className = 'player'
  document.body.appendChild(player)
  window


_destroyWindow = ->
  delete global.navigator
  delete global.window


# Initialize the window/document/navigator and add helpful functions for dealing
# with DOM elements.
beforeEach ->
  window  = _initDocument()
  React     = require('react')
  TestUtils = require('react/addons').addons.TestUtils

  @_nodes = []
  @render = (cls, el) ->
    if not el?
      el = document.createElement('div')
      document.body.appendChild(el)
      @_nodes.push(el)
    React.render(cls, el)

  @simulate   = TestUtils.Simulate
  @allByClass = TestUtils.scryRenderedDOMComponentsWithClass
  @allByTag   = TestUtils.scryRenderedDOMComponentsWithTag
  @allByType  = TestUtils.scryRenderedComponentsWithType
  @oneByClass = TestUtils.findRenderedDOMComponentWithClass
  @oneByTag   = TestUtils.findRenderedDOMComponentWithTag
  @oneByType  = TestUtils.findRenderedComponentWithType
  @allInTree  = TestUtils.findAllInRenderedTree

  @enterInput = (component, text) ->
    component.getDOMNode().value = text
    @simulate.change(component)

  @simulate.keyPress = (component, key) =>
    @simulate.keyDown(component, key)
    @simulate.keyUp(component, key)

# Nuke the global state of window/document/navigator
afterEach ->
  React = require('react')
  for node in @_nodes
    React.unmountComponentAtNode(node)
    node.remove()

  _destroyWindow()
