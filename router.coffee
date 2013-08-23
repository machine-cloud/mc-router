dd      = require("./lib/dd")
logfmt  = require('logfmt').namespace(ns: 'router')
request = require("request")

devices = require("./lib/expiring-list").init()

request.get "#{process.env.SERVICE_URL}/service/mqtt", (err, req, body) ->

  mc = require("./lib/machine-cloud").init(process.env.ID, process.env.MACHINE_CLOUD_URL)

  mc.on "message", (topic, body) ->
    console.log "topic", topic
    console.log "body", body

  xbee = require("./lib/xbee").init(process.env.XBEE_TTY)

  xbee.on "message", (message) ->
    devices.add "sensor.#{message.sender}", ->
      logfmt.time message, (logger) ->
        [message.key, message.value] = message.data.split("=")
        mc.send "tick", id:"sensor.#{message.sender}", strength:message.strength, key:message.key, value:message.value
        dd.delay 1000, -> xbee.send message.sender, "ack=#{message.key}"
        logger.log()

  devices.on "expire", (id) -> mc.send "disconnect", id:id

  dd.every 2000, ->
    mc.send "tick", id:process.env.ID, key:"devices", value:devices.count()
