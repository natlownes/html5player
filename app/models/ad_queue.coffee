FillingQueue = require './filling_queue'

module.exports = class AdQueue extends FillingQueue

  constructor: (@api, @assetBank, @size) ->
    super(@size)

  fill: =>
    @api.fetch
      success: (ad) =>
        this.push(ad)
        @assetBank.register(ad)

      error: =>
        ad = @assetBank.getAd(@api.config)
        this.push(ad)
