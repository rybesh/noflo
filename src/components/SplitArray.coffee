noflo = require "noflo"

class SplitArray extends noflo.Component
    constructor: ->
        @inPorts =
            in: new noflo.Port()
        @outPorts =
            out: new noflo.ArrayPort()

        @inPorts.in.on "begingroup", (group) =>
            @outPorts.out.beginGroup group
        @inPorts.in.on "data", (data) =>
            if toString.call(data) is '[object Array]'
                @outPorts.out.send item for item in data
                return
            @outPorts.out.send data
        @inPorts.in.on "endgroup", =>
            @outPorts.out.endGroup()
        @inPorts.in.on "disconnect", (data) =>
            @outPorts.out.disconnect()

exports.getComponent = -> new SplitArray
