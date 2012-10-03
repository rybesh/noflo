noflo = require "noflo"

class GroupByObjectKey extends noflo.Component
    constructor: ->
        @data = []
        @key = null
        @ingroup = null

        @inPorts =
            in: new noflo.Port()
            key: new noflo.Port()
        @outPorts =
            out: new noflo.Port()

        @inPorts.in.on "connect", =>
            @data = []
        @inPorts.in.on "begingroup", (group) =>
            @outPorts.out.beginGroup group
        @inPorts.in.on "data", (data) =>
            return @getKey data if @key?
            @data.push data
        @inPorts.in.on "endgroup", =>
            @outPorts.out.endGroup()
        @inPorts.in.on "disconnect", =>
            unless @data.length
                # Data already sent
                @outPorts.out.endGroup() if @ingroup?
                @outPorts.out.disconnect()
                return

            # No key, data will be sent when we get it
            return unless @key?

            # Otherwise send data we have an disconnect
            @getKey data for data in @data
            @outPorts.out.endGroup() if @ingroup?
            @outPorts.out.disconnect()

        @inPorts.key.on "data", (data) =>
            @key = data
        @inPorts.key.on "disconnect", =>
            return unless @data.length

            @getKey data for data in @data
            @outPorts.out.endGroup() if @ingroup?
            @outPorts.out.disconnect()

    getKey: (data) ->
        throw "Key not defined" unless @key?
        keys = if @key instanceof Array then @key else [@key]

        beginGroup = endGroup = nextGroup = null

        if typeof data is "object"
            for key in keys
                if key instanceof Object
                    if "type" of key
                        beginGroup = data[key.key] if data[key.type] is key.begin
                        endGroup = data[key.key] if data[key.type] is key.end
                    else
                        nextGroup = beginGroup = data[key.key]
                else
                    beginGroup = endGroup = data[key]
                if beginGroup? or endGroup?
                    if not (beginGroup? and endGroup?)
                        @outPorts.out.endGroup() if @ingroup?
                        @ingroup = nextGroup
                    break

        @outPorts.out.beginGroup beginGroup.toString() if beginGroup?
        @outPorts.out.send data
        @outPorts.out.endGroup() if endGroup?

exports.getComponent = -> new GroupByObjectKey
