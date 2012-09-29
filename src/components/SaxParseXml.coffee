noflo = require "noflo"
strict = true
sax = require "sax"

class SaxParseXml extends noflo.AsyncComponent
    constructor: ->
        @strict = true
        @options = {}
        @parser = null
        @accept = []
        @reject = []
        @capturing = [false]

        @inPorts =
            in: new noflo.Port()
            accept: new noflo.Port()
            reject: new noflo.Port()
            options: new noflo.Port()
        @outPorts =
            out: new noflo.Port()
            error: new noflo.Port()

        @inPorts.options.on "data", (data) =>
            @setOptions data
        @inPorts.accept.on "data", (data) =>
            @accept.push data
            @updateTagHandlers() if @parser?
        @inPorts.reject.on "data", (data) =>
            @reject.push data
            @updateTagHandlers() if @parser?

        super()

    setOptions: (options) ->
        throw "parser already initialized" if @parser?
        throw "options is not an object" unless typeof options is "object"
        for own key, value of options
            @options[key] = value

    updateTagHandlers: ->
        @parser.onopentag = (node) =>
            if node.name in @accept
                @capturing.push true
            else if node.name in @reject
                @capturing.push false
            if @capturing[-1..][0]
                @outPorts.out.beginGroup node.name
                if (k for k of node.attributes).length > 0
                    @outPorts.out.send node.attributes
        @parser.onclosetag = (name) =>
            if @capturing[-1..][0]
                @outPorts.out.endGroup name
            if name in @accept or name in @reject
                @capturing.pop()

    initParser: ->
        @parser = sax.parser @strict, @options
        @parser.ontext = (text) =>
            @outPorts.out.send text if @capturing[-1..][0]
        @parser.onerror = (err) =>
            @outPorts.error.send err
            @parser.resume()
        @updateTagHandlers()

    doAsync: (xml, callback) ->
        @initParser() unless @parser?
        return callback new Error "not ready" if @parser.closed
        @parser.write(xml)
        callback null

exports.getComponent = -> new SaxParseXml
