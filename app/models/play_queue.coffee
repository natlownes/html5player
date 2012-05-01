FillingQueue = require './filling_queue'

module.exports = class PlayQueue extends FillingQueue

  constructor: (@adQueue, @size, @$imagePlayer, @$videoPlayer) ->
    super(@size)

  fill: ->
    next = @adQueue.pop()
    
    if next
      this.push(next)

  play: =>
    ad = this.pop()

    if not ad
      return setTimeout(this.play, 500)

    this.display(ad)

  sendProofOfPlay: (url) ->
    $.ajax
      type:     'GET'
      url:      url

      success:  ->
        console.log("proof of play sent.")

      error:    ->
        console.log("error sending proof of play.")

  expire: (url) ->
    $.ajax
      type:     'GET'
      url:      url

      success:  ->
        console.log("lease expired.")
      
      error: ->
        console.log("error expiring lease.")

  display: (ad) ->
    console.log("displaying ad: " + ad.asset_url)
    duration = ad.length_in_seconds * 1000

    @$videoPlayer.unbind('ended')

    @$imagePlayer.hide()
    @$videoPlayer.hide()

    if ad.mime_type.match(/^image\//)
      @$imagePlayer.attr('src', ad.asset_url)
      @$imagePlayer.show()
      setTimeout( =>
        this.play()
        this.sendProofOfPlay(ad.proof_of_play_url)
      , duration)
    else if ad.mime_type.match(/^video\//)
      @$videoPlayer.attr('src', ad.asset_url)
      @$videoPlayer.show()
      @$videoPlayer.get(0).play()
      @$videoPlayer.bind('ended', =>
        this.sendProofOfPlay(ad.proof_of_play_url)
        this.play()
      )
    else
      this.expire(ad.expiration.url)
      this.play()
