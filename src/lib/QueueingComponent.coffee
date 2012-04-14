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

        @groups = []
        @inPorts.in.on "begingroup", (group) =>
            @groups.push group
        @inPorts.in.on "endgroup", =>
            @groups.pop()

    push: (func, args) ->
        groups = @groups.slice 0 # make a copy
        task = do (args, groups) =>
            return (callback) =>
                args.push groups
                args.push callback
                func.apply this, args
        @_queue.push task
        @outPorts.queued.send @_queue.length() if @outPorts.queued.socket


exports.QueueingComponent = QueueingComponent
