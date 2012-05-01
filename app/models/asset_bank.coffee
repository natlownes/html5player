module.exports = class AssetBank

  register: (ad) ->
    localStorage["ad-" + ad.asset_id] = JSON.stringify(ad)

  getAd: (config) ->
    ads = []

    for k, v of localStorage
      ad = JSON.parse(v)
      if k.indexOf("ad-") is 0 and ad.width = config.width and ad.height = config.height
        ads.push(ad)

    rand = Math.floor(Math.random() * ads.length)
    ads[rand]
