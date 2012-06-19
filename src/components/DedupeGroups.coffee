noflo = require "noflo"

class DedupeGroups extends noflo.Component
    constructor: ->
        @inPorts =
            in: new noflo.Port()
        @outPorts =
            out: new noflo.Port()
        @lastGroup = null
        @send = []

        @inPorts.in.on "begingroup", (group) =>
            send = (group isnt @lastGroup)
            @outPorts.out.beginGroup group if send
            @send.push send
            @lastGroup = group
        @inPorts.in.on "endgroup", =>
            @outPorts.out.endGroup() if @send.pop()
        @inPorts.in.on "data", (data) =>
            @outPorts.out.send data
        @inPorts.in.on "disconnect", =>
            @outPorts.out.disconnect()

exports.getComponent = -> new DedupeGroups
