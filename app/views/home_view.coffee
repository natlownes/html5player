View = require './view'
template = require './templates/home'

VistarConfig = require '../models/vistar_config'
VistarPlayer = require '../models/vistar_player'

module.exports = class HomeView extends View
  id: 'player-view'
  template: template
