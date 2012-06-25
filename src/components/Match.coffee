noflo = require "noflo"

class Match extends noflo.Component
    description: "This component receives data on a single input port and sends the same data out to all connected output ports"

    constructor: ->
        @inPorts =
            in: new noflo.Port()
            regex: new noflo.Port()
        @outPorts =
            match: new noflo.ArrayPort()
            out: new noflo.Port()

        @regexes = []
        @inPorts.regex.on "data", (data) =>
            @regexes.push new RegExp data

        @inPorts.in.on "begingroup", (group) =>
            @outPorts.out.beginGroup group
        @inPorts.in.on "data", (data) =>
            matched = false
            for re, i in @regexes
                if re.test data
                    matched = true
                    @outPorts.match.send data, i
            @outPorts.out.send data unless matched
        @inPorts.in.on "endgroup", =>
            @outPorts.out.endGroup()
        @inPorts.in.on "disconnect", =>
            @outPorts.out.disconnect()

exports.getComponent = ->
    new Match
