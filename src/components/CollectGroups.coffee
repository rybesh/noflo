noflo = require "noflo"
assert = require "assert"

class CollectGroups extends noflo.Component
    constructor: ->
        @data = {}
        @groups = []
        @parents = []
        @tocollect = []
        @collecting = true

        @inPorts =
            in: new noflo.Port()
            groups: new noflo.Port()
        @outPorts =
            out: new noflo.Port()

        @inPorts.in.on "connect", =>
            @data = {}
        @inPorts.in.on "begingroup", (group) =>
            if @tocollect.length > 0 and not (group in @tocollect)
                @collecting = false
                @sendData()
                return @outPorts.out.beginGroup group
            throw new Error "groups cannot be named '$data'" if group == "$data"
            @collecting = true
            @parents.push @data
            @groups.push group
            @data = {}
        @inPorts.in.on "data", (data) =>
            return @outPorts.out.send data if not @collecting
            @setData data
        @inPorts.in.on "endgroup", =>
            return @outPorts.out.endGroup() if not @collecting
            data = @data
            @data = @parents.pop()
            @addChild @data, @groups.pop(), data
        @inPorts.in.on "disconnect", =>
            @sendData()
            @outPorts.out.disconnect()

        @inPorts.groups.on "data", (data) =>
            @tocollect = data

    sendData: ->
        if (Object.keys @data).length > 0
            @outPorts.out.send @data
            @data = {}

    addChild: (parent, child, data) ->
        return parent[child] = data unless child of parent
        return parent[child].push data if Array.isArray parent[child]
        parent[child] = [ parent[child], data ]

    setData: (data) ->
        @data.$data = [] unless "$data" of @data
        @data.$data.push data

    setDataToKey: (target, key, value) ->
        target[key].value = value

exports.getComponent = -> new CollectGroups
