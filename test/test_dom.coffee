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


# Nuke the global state of window/document/navigator
afterEach ->
  _destroyWindow()
