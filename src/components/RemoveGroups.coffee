noflo = require "noflo"

class RemoveGroups extends noflo.Component
    constructor: ->
        @reject = []
        @removed = []

        @inPorts =
            in: new noflo.Port()
            remove: new noflo.Port()
        @outPorts =
            out: new noflo.Port()

        @inPorts.in.on "begingroup", (group) =>
            return @removed.push true unless @reject.length > 0
            if group in @reject
                @removed.push true
            else
                @outPorts.out.beginGroup group
                @removed.push false
        @inPorts.in.on "data", (data) =>
            @outPorts.out.send data
        @inPorts.in.on "endgroup", =>
            return if @removed.pop()
            @outPorts.out.endGroup()
        @inPorts.in.on "disconnect", =>
            @outPorts.out.disconnect()

        @inPorts.remove.on "data", (data) =>
            data = [data] unless data instanceof Array
            @reject.push d for d in data

exports.getComponent = -> new RemoveGroups
