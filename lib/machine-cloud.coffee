dd      = require("./dd")
events  = require("events")
logfmt  = require('logfmt').namespace(ns: 'router.mc')
request = require("request")

exports.MachineCloud = class MachineCloud extends events.EventEmitter

  constructor: (@id, @url) ->
    request.get "#{@url}/service/mqtt", (err, req, body) =>
      @mqtt = require("./mqtt-url").connect(body)
      @mqtt.on "connect", =>
        @mqtt.subscribe @id.split(".")[0]
        @mqtt.subscribe @id
      @mqtt.on "message", (topic, body) =>
        @emit "message", topic, JSON.parse(body)
      dd.every 2000, =>
        @send "tick", id:@id, key:"model", value:"ROUTER01"

  send: (topic, message) ->
    logfmt.time dd.merge(message, at: 'send', topic: topic), (logger) =>
      @mqtt.publish topic, JSON.stringify(message), (err) ->
        if err then log.log(error: err.message) else logger.log()

exports.init = (args...) ->
  new MachineCloud(args...)
