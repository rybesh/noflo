noflo = require "noflo"
splitta = require "splitta"

class SplitSentences extends noflo.AsyncComponent
    constructor: ->

        @ready = false
        splitta.loadModel (err, model) =>
            throw err if err
            @model = model
            @ready = true
            @emit "ready"

        @inPorts =
            in: new noflo.Port()
        @outPorts =
            out: new noflo.Port()
            error: new noflo.Port()
        super()

    isReady: ->
        @ready

    doAsync: (text, callback) ->
        return callback null unless text.length > 0
        @model.segment text, (err, sentences) =>
            return callback err if err?
            @outPorts.out.send sentence for sentence in sentences
            callback null

exports.getComponent = -> new SplitSentences
