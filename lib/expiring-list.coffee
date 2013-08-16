dd     = require("./dd")
events = require("events")

exports.ExpiringList = class ExpiringList extends events.EventEmitter

  constructor: (@timeout=2000) ->
    @list = {}
    dd.every (@timeout+2000), =>
      for key in dd.keys(@list)
        if @list[key] < dd.now()
          @emit "expire", key
          delete @list[key]

  add: (key, cb) ->
    old = @list[key]
    @list[key] = dd.now() + @timeout
    cb(old) if cb

  list: ->
    dd.keys(@list)

  count: ->
    dd.keys(@list).length

exports.init = (args...) ->
  new ExpiringList(args...)
