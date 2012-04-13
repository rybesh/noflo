async = require "async"
port = require "./Port"
component = require "./Component"

class QueueingComponent extends component.Component

    constructor: ->
        @inPorts.concurrency = new port.Port()
        @outPorts.queued = new port.Port()
        @outPorts.saturated = new port.Port()
        @outPorts.empty = new port.Port()
        @outPorts.drain = new port.Port()

        @_queue = async.queue ((task, callback) =>
            task callback
        ), 2 # of workers
        @_queue.saturated = =>
            @outPorts.saturated.send @_queue.length() if @outPorts.saturated.socket
        @_queue.empty = =>
            @outPorts.empty.send true if @outPorts.empty.socket
        @_queue.drain = =>
            @outPorts.drain.send true  if @outPorts.drain.socket

        @inPorts.concurrency.on "data", (data) =>
            @_queue.concurrency = data

    push: (task) ->
        @_queue.push task
        @outPorts.queued.send @_queue.length() if @outPorts.queued.socket


exports.QueueingComponent = QueueingComponent
