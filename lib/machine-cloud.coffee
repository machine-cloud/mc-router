dd      = require("./dd")
events  = require("events")
log     = require("./logger").init("router.mc")
request = require("request")

exports.MachineCloud = class MachineCloud extends events.EventEmitter

  constructor: (@id, @url) ->
    request.get "#{@url}/service/mqtt", (err, req, body) =>
      @mqtt = require("./mqtt-url").connect(body)
      @mqtt.on "connect", =>
        @mqtt.publish "connect", JSON.stringify(id:@id, model:"ROUTER01")
        @mqtt.subscribe @id.split(".")[0]
        @mqtt.subscribe @id
      @mqtt.on "message", (topic, body) =>
        @emit "message", topic, JSON.parse(body)
      dd.every 2000, =>
        @mqtt.publish "tick", JSON.stringify(id:@id)

  send: (topic, message) ->
    log.start "send", dd.merge(message, topic:topic), (log) =>
      @mqtt.publish topic, JSON.stringify(message), (err) ->
        if err then log.error(err) else log.success()

exports.init = (args...) ->
  new MachineCloud(args...)
