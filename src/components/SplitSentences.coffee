noflo = require "noflo"
splitta = require "splitta"

class SplitSentences extends noflo.QueueingComponent
    constructor: ->

        @ready = false
        splitta.loadModel (err, model) =>
            throw err if err?
            @model = model
            @ready = true
            @emit "ready"

        @inPorts =
            in: new noflo.Port()
        @outPorts =
            out: new noflo.Port()
            error: new noflo.Port()

        text = ""
        @inPorts.in.on "connect", =>
            text = ""
        @inPorts.in.on "begingroup", (group) =>
            @push (callback) =>
                @outPorts.out.beginGroup group
                callback()
        @inPorts.in.on "data", (data) =>
            text += data
        @inPorts.in.on "endgroup", =>
            @push do (text) =>
                return (callback) =>
                    @splitSentences text, =>
                        @outPorts.out.endGroup()
                        callback()
            text = ""
        @inPorts.in.on "disconnect", =>
            @push do (text) =>
                return (callback) =>
                    @splitSentences text, =>
                        @outPorts.out.disconnect()
                        callback()
            text = ""

        super "SplitSentences"

    isReady: ->
        console.log "ready? ", @ready
        @ready

    splitSentences: (text, callback) ->
        return callback() unless text.length > 0
        @model.segment text, (err, sentences) =>
            if err
                @outPorts.error.send err
                @outPorts.error.disconnect()
                return callback()
            @outPorts.out.send sentence for sentence in sentences
            callback()

exports.getComponent = -> new SplitSentences
