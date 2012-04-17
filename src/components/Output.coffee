noflo = require "noflo"
util = require "util"
colors = require "colors"

class Output extends noflo.Component

    description: "This component receives input on a single inport, and sends the data items directly to console.log"

    constructor: ->
        @options =
            showHidden: false
            depth: 2
            colors: false
            groups: false
            error: false

        @inPorts =
            in: new noflo.ArrayPort()
            options: new noflo.Port()

        @outPorts = {}

        @inPorts.in.on "begingroup", (group) =>
            @log ""
            @log "[    group ] #{group}".magenta if @options.groups
        @inPorts.in.on "data", (data) =>
            @log data
        @inPorts.in.on "endgroup", =>
            @log "[ endgroup ]".magenta if @options.groups
            @log ""

        @inPorts.options.on "data", (data) =>
            @setOptions data

    setOptions: (options) ->
        throw "Options is not an object" unless typeof options is "object"
        for own key, value of options
            @options[key] = value

    log: (data) ->
        logger = if @options.error then console.error else console.log
        return logger data unless typeof data == "object"
        logger util.inspect data,
            @options.showHidden, @options.depth, @options.colors

exports.getComponent = ->
    new Output()
