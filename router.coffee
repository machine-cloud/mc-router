dd      = require("./lib/dd")
log     = require("./lib/logger").init("router")
request = require("request")

request.get "#{process.env.SERVICE_URL}/service/mqtt", (err, req, body) ->

  mc = require("./lib/machine-cloud").init("router.001", process.env.MACHINE_CLOUD_URL)

  mc.on "message", (topic, body) ->
    console.log "topic", topic
    console.log "body", body

  xbee = require("./lib/xbee").init("/dev/tty.usbserial-A601F1ZN")

  xbee.on "message", (message) ->
    [message.key, message.value] = message.data.split("=")
    log.start "message", (log) ->
      mc.send "tick", id:"sensor.#{message.sender}", strength:message.strength, key:message.key, value:message.value
      dd.delay 1000, ->
        xbee.send message.sender, "ack=#{message.key}", (err) ->
      log.success()
