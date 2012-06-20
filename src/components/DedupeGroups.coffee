noflo = require "noflo"

class DedupeGroups extends noflo.Component
    constructor: ->
        @inPorts =
            in: new noflo.Port()
        @outPorts =
            out: new noflo.Port()
        @lastGroup = null
        @sendgroup = []
        @senddisconnect = true

        @inPorts.in.on "begingroup", (group) =>
            send = (group isnt @lastGroup)
            @outPorts.out.beginGroup group if send
            @sendgroup.push send
            @lastGroup = group
        @inPorts.in.on "endgroup", =>
            @outPorts.out.endGroup() if @sendgroup.pop()
        @inPorts.in.on "data", (data) =>
            @outPorts.out.send data
        @inPorts.in.on "disconnect", =>
            @outPorts.out.disconnect() if @senddisconnect
            @senddisconnect = (not @senddisconnect)

exports.getComponent = -> new DedupeGroups
