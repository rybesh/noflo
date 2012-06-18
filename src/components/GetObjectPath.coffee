noflo = require "noflo"
jsonpath = require "jsonpath"

class GetObjectPath extends noflo.Component
    constructor: ->
        @path = null
        @q = []

        @inPorts =
            in: new noflo.Port()
            path: new noflo.Port()
        @outPorts =
            out: new noflo.Port()
            error: new noflo.Port()

        @inPorts.in.on "begingroup", (group) => @handle ["begingroup", group]
        @inPorts.in.on "data", (data) => @handle ["data", data]
        @inPorts.in.on "endgroup", => @handle ["endgroup"]
        @inPorts.in.on "disconnect", => @handle ["disconnect"]

        @inPorts.path.on "data", (data) =>
            unless @validate data
                return @outPorts.error.send "invalid path: #{data}"
            @path = data
            while @q.length > 0
                @handle @q.shift()

    validate: (path) ->
        return false unless path? and path.length > 2
        return path.slice(0,2) == "$."

    handle: ([event, data]) ->
        return @q.push [event, data] unless @path?
        switch event
            when "begingroup" then @outPorts.out.beginGroup data
            when "endgroup" then @outPorts.out.endGroup()
            when "disconnect" then @outPorts.out.disconnect()
            when "data" then @evaluatePath data

    evaluatePath: (o) ->
        @outPorts.out.send result for result in jsonpath.eval o, @path

exports.getComponent = -> new GetObjectPath
