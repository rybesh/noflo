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
        @queue.saturated = => @outPorts.saturated.send true
        @queue.empty = => @outPorts.empty.send true
        @queue.drain = => @outPorts.drain.send true

        @inPorts.concurrency.on "data", (data) =>
            @queue.concurrency = data

exports.QueueingComponent = QueueingComponent
