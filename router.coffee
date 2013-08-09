xbee = require("./lib/xbee").init("/dev/tty.usbserial-A601F1ZN")

setInterval (() -> xbee.send 0x5000, "ack=test", (err) ->
  console.log "sent ack"), 2000

xbee.on "rx16", (message) ->
  console.log "got rx16", JSON.stringify(message)
