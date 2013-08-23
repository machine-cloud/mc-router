dd         = require("./dd")
events     = require("events")
serialport = require("serialport")
logfmt     = require('logfmt').namespace(ns: 'router.xb')

XON      = 0x11
XOFF     = 0x13
ESCAPE   = 0x7d
START    = 0x7e
API_RX16 = 0x81

exports.XBee = class XBee extends events.EventEmitter

  constructor: (@port, @baud=9600) ->
    @serial = new serialport.SerialPort(@port, baudRate:@baud)
    @serial.on "open", =>
      @buffer = ""
      @serial.on "data", @data_received
      @serial.on "close", @closed

  send: (address, message, cb) ->
    logfmt.time at: 'send', (logger) =>
      packet = @build_packet 0x01, 0x01, address / 256, address % 256, 0x00, message
      @send_packet(packet, cb)
      logger.log(address:address, message:message)

  command: (command, response, timeout=5000) ->

  ## private #######################################################

  send_packet: (packet, cb) ->
    message = ""
    message += String.fromCharCode((packet.length-1) / 256)
    message += String.fromCharCode((packet.length-1) % 256)
    message += packet.toString("binary")
    message = String.fromCharCode(START) + @escape(message)
    @serial.write new Buffer(message, "binary")
    cb null if cb

  build_packet: (args...) ->
    packet = ""
    for arg in args
      packet += switch typeof(arg)
        when "number" then String.fromCharCode(arg)
        when "string" then arg
    sum = 0
    for byte in packet
      sum += byte.charCodeAt(0)
      sum %= 256
    packet += String.fromCharCode(255 - sum)
    new Buffer(packet, "binary")

  data_received: (data) =>
    @buffer += @unescape(data)
    @parse_buffer()

  closed: ->
    console.log "closed"

  escape: (data) ->
    data = @escape_char(data, ESCAPE)
    data = @escape_char(data, XON)
    data = @escape_char(data, XOFF)
    data = @escape_char(data, START)
    data

  escape_char: (data, char) ->
    idx = -2
    while (idx = data.indexOf(String.fromCharCode(char), idx+2)) > -1
      escaped = data.charCodeAt(idx) ^ 0x20
      data = data.slice(0, idx) + String.fromCharCode(ESCAPE) + String.fromCharCode(escaped) + data.slice(idx+1)
    data

  unescape: (data) ->
    str = data.toString("binary")
    while (idx = str.indexOf(String.fromCharCode(ESCAPE))) > -1
      char = 0x20 ^ str.charCodeAt(idx+1)
      str = str.slice(0, idx) + String.fromCharCode(char) + str.slice(idx+2)
    str

  parse_buffer: ->
    return if ((pos = @buffer.indexOf(String.fromCharCode(START))) is -1)
    return if @buffer.length < (pos+3)
    length = (@buffer.charCodeAt(pos+1) << 8) + @buffer.charCodeAt(pos+2)
    return if @buffer.length < (pos+length+4)
    data = new Buffer(@buffer, "binary").slice(pos+3, pos+length+4)
    @buffer = @buffer.slice(pos+length+4)
    @parse_packet data, (err, data) ->
      console.log "err", err
      console.log "data", data

  parse_packet: (packet, cb) ->
    command = packet[0]
    @checksum packet, (err, data) =>
      return cb(err) if err
      data = packet.slice(1, packet.length-1)
      switch command
        when API_RX16
          @emit "message",
            sender: (data[0] << 8) + data[1]
            strength: data[2]
            options: data[3]
            data: data.slice(4).toString("binary")

  checksum: (packet, cb) ->
    check = packet[packet.length-1]
    sum = 0
    for byte in packet.slice(0, packet.length-1)
      sum += byte
      sum %= 256
    if check is 255-sum
      cb null, packet.slice(0, packet.length-2)
    else
      console.log "checksum failed"
      cb null, packet.slice(0, packet.length-2)
      #cb new Error("checksum failed: got #{check} expecting #{255-sum}")

exports.init = (args...) ->
  new XBee(args...)
