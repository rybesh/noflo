noflo = require "noflo"
splitta = require "splitta"

class SplitSentences extends noflo.Component
    constructor: ->
        @text = ""
        @inPorts =
            in: new noflo.Port()
        @outPorts =
            out: new noflo.Port()
            error: new noflo.Port()

        text = ""
        @inPorts.in.on "connect", =>
            @text = ""
        @inPorts.in.on "begingroup", (group) =>
            @outPorts.out.beginGroup group
        @inPorts.in.on "data", (data) =>
            text += data
        @inPorts.in.on "endgroup", =>
            @once "split", =>
                @outPorts.out.endGroup()
            @text = text
            text = ""
            @splitSentences()
        @inPorts.in.on "disconnect", =>
            @once "split", =>
                @outPorts.out.disconnect()
            @text = text
            text = ""
            @splitSentences()

    splitSentences: ->
        return unless @text.length > 0
        splitta.segment @text, (err, sentences) =>
            if err
                @outPorts.error.send err
                return @outPorts.error.disconnect()
            @outPorts.out.send sentence for sentence in sentences
            @emit "split"

exports.getComponent = -> new SplitSentences
