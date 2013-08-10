dd   = require("./lib/dd")
xbee = require("./lib/xbee").init("/dev/tty.usbserial-A601F1ZN")

xbee.on "message", (message) ->
  console.log "message", JSON.stringify(message)
  [key, value] = message.data.split("=")
  dd.delay 1000, ->
    xbee.send message.sender, "ack=#{key}", (err) ->
      console.log "ack", sender:message.sender, key:key
