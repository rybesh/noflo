noflo = require "noflo"
strict = true
sax = require "sax"

class SaxParseXml extends noflo.AsyncComponent
    constructor: ->
        @strict = true
        @options = {}
        @parser = null
        @tags = []

        @inPorts =
            in: new noflo.Port()
            tags: new noflo.Port()
            options: new noflo.Port()
        @outPorts =
            out: new noflo.Port()
            error: new noflo.Port()

        @inPorts.options.on "data", (data) =>
            @setOptions data
        @inPorts.tags.on "data", (data) =>
            @tags.push data
            @setTags() if @parser?

        super()

    setOptions: (options) ->
        throw "parser already initialized" if @parser?
        throw "options is not an object" unless typeof options is "object"
        for own key, value of options
            @options[key] = value

    setTags: ->
        @parser.onopentag = (node) =>
            if node.name in @tags
                @outPorts.out.beginGroup node.name
        @parser.onclosetag = (name) =>
            if name in @tags
                @outPorts.out.endGroup()

    initParser: ->
        @parser = sax.parser @strict, @options
        @parser.ontext = (text) =>
            @outPorts.out.send text if @parser.tag.name in @tags
        @parser.onerror = (err) =>
            @outPorts.error.send err
            @parser.resume()
        @setTags()

    doAsync: (xml, callback) ->
        @initParser() unless @parser?
        return callback new Error "not ready" if @parser.closed
        @parser.write(xml)
        callback null

exports.getComponent = -> new SaxParseXml
