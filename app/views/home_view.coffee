View = require './view'
template = require './templates/home'

VistarConfig = require '../models/vistar_config'
VistarPlayer = require '../models/vistar_player'

module.exports = class HomeView extends View
  id: 'player-view'
  template: template

  afterRender: ->
    config = new VistarConfig
      apiKey:     "eb7d6e26-5930-4fef-a3c7-aa023f31cefd"
      networkId:  "24ba0582-7648-48b2-a7f4-0af3783b55f0"
      width:      1280
      height:     720

    $imagePlayer = @$el.find('#image-player')
    $videoPlayer = @$el.find('#video-player')

    player = new VistarPlayer(config, $imagePlayer, $videoPlayer)

    player.play()
