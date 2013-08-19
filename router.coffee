dd      = require("./lib/dd")
log     = require("./lib/logger").init("router")
request = require("request")

devices = require("./lib/expiring-list").init()

request.get "#{process.env.SERVICE_URL}/service/mqtt", (err, req, body) ->

  mc = require("./lib/machine-cloud").init(process.env.ID, process.env.MACHINE_CLOUD_URL)

  mc.on "message", (topic, message) ->
    try
      xbee.send parseInt(/device\.sensor\.(.*)$/.exec(topic)[1]), "#{message.key}=#{message.value}"
    catch err
      console.log "err", err

  xbee = require("./lib/xbee").init(process.env.XBEE_TTY)

  xbee.on "message", (message) ->
    devices.add "sensor.#{message.sender}", (old) ->
      log.start "message", (log) ->
        [message.key, message.value] = message.data.split("=")
        mc.send "tick", id:"sensor.#{message.sender}", strength:message.strength, key:message.key, value:message.value
        mc.subscribe "sensor.#{message.sender}" unless old
        log.success()

  devices.on "expire", (id) -> mc.send "disconnect", id:id

  dd.every 2000, ->
    mc.send "tick", id:process.env.ID, key:"devices", value:devices.count()
