noflo = require "noflo"
xml2js = require "xml2js"

class ParseXml extends noflo.AsyncComponent
    constructor: ->
        @options = # defaults recommended by xml2js docs
            normalize: false
            trim: false
            explicitRoot: true

        @inPorts =
            in: new noflo.Port()
            options: new noflo.Port()
        @outPorts =
            out: new noflo.Port()

        @inPorts.options.on "data", (data) =>
            @setOptions data

        super()

    setOptions: (options) ->
        throw "Options is not an object" unless typeof options is "object"
        for own key, value of options
            @options[key] = value

    doAsync: (xml, callback) ->
        parser = new xml2js.Parser @options
        parser.parseString xml, (err, o) =>
            return callback err if err?
            @outPorts.out.send o
            callback null

exports.getComponent = -> new ParseXml
