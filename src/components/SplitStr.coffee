# The SplitStr component receives a string in the in port, splits it by
# string specified in the delimiter port, and send each part as a separate
# packet to the out port

noflo = require "noflo"

class SplitStr extends noflo.Component
    constructor: ->
        @delimiter = "\n"

        @inPorts =
            in: new noflo.Port()
            delimiter: new noflo.Port()
        @outPorts =
            out: new noflo.Port()

        @inPorts.delimiter.on "data", (data) =>
            @delimiter = data
        @inPorts.in.on "begingroup", (data) =>
            @outPorts.out.beginGroup data
        @inPorts.in.on "data", (data) =>
            data.split(@delimiter).forEach (part) =>
                @outPorts.out.send part
        @inPorts.in.on "endgroup", (data) =>
            @outPorts.out.endGroup()
        @inPorts.in.on "disconnect", (data) =>
            @outPorts.out.disconnect()

exports.getComponent = ->
    new SplitStr()
