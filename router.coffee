dd      = require("./lib/dd")
log     = require("./lib/logger").init("router")
request = require("request")

devices = require("./lib/expiring-list").init()

request.get "#{process.env.SERVICE_URL}/service/mqtt", (err, req, body) ->

  mc = require("./lib/machine-cloud").init(process.env.ID, process.env.MACHINE_CLOUD_URL)

  mc.on "message", (topic, body) ->
    console.log "topic", topic
    console.log "body", body

  xbee = require("./lib/xbee").init(process.env.XBEE_TTY)

  xbee.on "message", (message) ->

    # add to the device list
    devices.add "sensor.#{message.sender}", ->

      log.start "message", (log) ->

        # split the data from key=value
        [message.key, message.value] = message.data.split("=")

        # we get the model keyword on connection
        mc.send "connect", id:"sensor.#{message.sender}", model:message.value if message.key is "model"

        # send the metric as a tick
        mc.send "tick", id:"sensor.#{message.sender}", strength:message.strength, key:message.key, value:message.value

        # ack in 1s
        dd.delay 1000, ->
          xbee.send message.sender, "ack=#{message.key}"

        log.success()

  devices.on "expire", (id) -> mc.send "disconnect", id:id
