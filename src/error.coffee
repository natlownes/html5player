module.exports =

  requestErrorBody: (respOrEvent) ->
    # get JSON serializable representation of error for logger
    #
    # ajax lib will reject either with the body of the request (parsed if json,
    # string otherwise) or XMLHttpRequestProgressEvent if some other network
    # problem
    if respOrEvent.currentTarget?.status is 0
      'Server or device network down'
    else
      respOrEvent
