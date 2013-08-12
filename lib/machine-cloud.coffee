events  = require("events")
log     = require("./logger").init("router.mc")
request = require("request")

exports.MachineCloud = class MachineCloud extends events.EventEmitter

  constructor: (@id, @url) ->
    request.get "#{@url}/service/mqtt", (err, req, body) =>
      @mqtt = require("./mqtt-url").connect(body)
      @mqtt.on "connect", =>
        @mqtt.publish "register", JSON.stringify(id:@id)
        @mqtt.subscribe @id.split(".")[0]
        @mqtt.subscribe @id
      @mqtt.on "message", (topic, body) =>
        @emit "message", topic, JSON.parse(body)

  send: (topic, message) ->
    log.start "send", message, (log) =>
      @mqtt.publish topic, JSON.stringify(message), (err) ->
        console.log "err", err
        if err then log.error(err) else log.success()

exports.init = (args...) ->
  new MachineCloud(args...)
