noflo = require "noflo"
strict = true
sax = require "sax"
util = require "util"

# By default, capture nothing.
#
# If a tag opens that is being accepted,
# start capturing everything, including subelements, until
# 1) another tag that is being accepted opens, or
# 2) the accepted tag closes.
# In either event send off the captured data.
#
# If a tag opens that is being rejected,
# stop capturing anything, until
# 1) a tag that is being accepted opens, or
# 2) the rejected tag closes.
#
# Keep references to:
#   stack of accepted (tag + attributes)
#   send an object (tag + attributes) whenever a new accepted tag opens
#   pop accepted stack when an accepted tag closes


class SaxParseXml extends noflo.AsyncComponent
    constructor: ->
        @strict = true
        @options = {}
        @parser = null
        @accept = []
        @reject = []
        @accepted = []
        @data = null
        @text = ''
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
            @setOptions data unless typeof options is "object"
        @inPorts.accept.on "data", (data) =>
            data = [data] unless data instanceof Array
            @accept.push d for d in data
            @updateTagHandlers() if @parser?
        @inPorts.reject.on "data", (data) =>
            data = [data] unless data instanceof Array
            @reject.push d for d in data
            @updateTagHandlers() if @parser?

        super()

    setOptions: (options) ->
        throw "parser already initialized" if @parser?
        throw "options is not an object" unless options instanceof Object
        for own key, value of options
            @options[key] = value

    clone: (o) ->
        if not o? or typeof o isnt 'object'
            return o

        if o instanceof Date
            return new Date(o.getTime())

        if o instanceof RegExp
            flags = ''
            flags += 'g' if o.global?
            flags += 'i' if o.ignoreCase?
            flags += 'm' if o.multiline?
            flags += 'y' if o.sticky?
            return new RegExp(o.source, flags)

        newInstance = new o.constructor()

        for key of o
            newInstance[key] = @clone o[key]

        return newInstance

    sendData: (o) ->
        o[o._name].push @text if @text.length > 0
        @text = ''
        delete o._name
        @outPorts.out.send o

    updateTagHandlers: ->
        @parser.onopentag = (node) =>
            if node.name in @reject
                @capturing.push false
                return
            if node.name in @accept
                @capturing.push true
                if @accepted.length > 0
                    data = @accepted.pop()
                    copy = @clone data
                    @sendData copy
                    data[data._name] = []
                    @accepted.push data
            return unless @capturing[-1..][0]
            @data = {}
            @data._name = node.name
            @data[node.name] = []
            @data[k] = v for k,v of node.attributes
            if node.name in @accept
                @accepted.push @data
            else
                parent = @accepted.pop()
                parent[parent._name].push @data
                @accepted.push parent

        @parser.onclosetag = (name) =>
            if name in @accept
                @capturing.pop()
                if @accepted.length > 0
                    return @sendData @accepted.pop()
            if name in @reject
                return @capturing.pop()
            if @capturing[-1..][0]
                @data[@data._name].push @text if @text.length > 0
                @text = ''
                delete @data._name

    initParser: ->
        @parser = sax.parser @strict, @options
        @parser.ontext = (text) =>
            @text += text if @capturing[-1..][0]
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
