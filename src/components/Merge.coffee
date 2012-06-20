noflo = require "noflo"

class Merge extends noflo.Component
    description: "This component receives data on multiple input ports and sends the same data out to the connected output port"

    constructor: ->
        @inPorts =
            in: new noflo.ArrayPort()
            mergeControlPackets: new noflo.Port()
        @outPorts =
            out: new noflo.Port()

        @mergeControlPackets = false
        @groups = []
        @connects = []
        @samegroups = 0
        @sendgroup = []

        @inPorts.mergeControlPackets.on "data", (data) =>
            unless typeof data is "boolean"
                throw new Error "mergeControlPackets only accepts true or false"
            @mergeControlPackets = data

        @inPorts.in.on "connect", =>
            unless @mergeControlPackets
                return @outPorts.out.connect()
            send = (@connects.length % @inPorts.in.sockets.length == 0)
            @outPorts.out.connect() if send
            @connects.push send
        @inPorts.in.on "begingroup", (group) =>
            unless @mergeControlPackets
                return @outPorts.out.beginGroup group
            lastGroup = @groups.pop()
            @samegroups = if group is lastGroup then (@samegroups + 1) else 1
            @groups.push lastGroup
            @groups.push group
            send = (@samegroups % @inPorts.in.sockets.length == 1)
            @outPorts.out.beginGroup group if send
            @sendgroup.push send
        @inPorts.in.on "data", (data) =>
            @outPorts.out.send data
        @inPorts.in.on "endgroup", =>
            unless @mergeControlPackets
                return @outPorts.out.endGroup()
            @groups.pop()
            @outPorts.out.endGroup() if @sendgroup.pop()
        @inPorts.in.on "disconnect", =>
            unless @mergeControlPackets
                return @outPorts.out.disconnect()
            @outPorts.out.disconnect() if @connects.pop()

exports.getComponent = ->
    new Merge
