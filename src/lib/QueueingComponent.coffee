async = require "async"
port = require "./Port"
component = require "./Component"

class QueueingComponent extends component.Component

    constructor: ->
        @inPorts.concurrency = new port.Port()
        @outPorts.saturated = new port.Port()
        @outPorts.empty = new port.Port()
        @outPorts.drain = new port.Port()

        @queue = async.queue ((task, callback) =>
            task callback
        ), 2 # 2 workers
        @queue.saturated = =>
            @outPorts.saturated.send true if @outPorts.saturated.socket
        @queue.empty = =>
            @outPorts.empty.send true if @outPorts.empty.socket
        @queue.drain = =>
            @outPorts.drain.send true  if @outPorts.drain.socket

        @inPorts.concurrency.on "data", (data) =>
            @queue.concurrency = data

exports.QueueingComponent = QueueingComponent
