noflo = require "noflo"
jsdom = require "jsdom"
fs = require "fs"

class ScrapeHtml extends noflo.QueueingComponent
    constructor: ->
        @jquery = "http://code.jquery.com/jquery.min.js"
        @jquerysrc = "scripts"
        @textSelector = ""
        @ignoreSelectors = []

        @inPorts =
            in: new noflo.Port()
            jquery: new noflo.Port()
            textSelector: new noflo.Port()
            ignoreSelector: new noflo.ArrayPort()
        @outPorts =
            out: new noflo.Port()
            error: new noflo.Port()

        html = ""
        @inPorts.in.on "connect", =>
            html = ""
        @inPorts.in.on "begingroup", (group) =>
            @queue.push (callback) =>
                @outPorts.out.beginGroup group
                callback()
        @inPorts.in.on "data", (data) =>
            html += data
        @inPorts.in.on "endgroup", =>
            @queue.push do (html) =>
                return (callback) => @scrapeHtml html, callback
            html = ""
            @queue.push (callback) =>
                @outPorts.out.endGroup()
                callback()
        @inPorts.in.on "disconnect", =>
            @queue.push do (html) =>
                return (callback) => @scrapeHtml html, callback
            html = ""
            @queue.push (callback) =>
                @outPorts.out.disconnect()
                callback()

        @inPorts.jquery.on "data", (data) =>
            return @jquery = data if data.indexOf("http://") == 0
            @jquery = fs.readFileSync(data).toString();
            @jquerysrc = "src"

        @inPorts.textSelector.on "data", (data) =>
            @textSelector = data
        @inPorts.textSelector.on "disconnect", =>
            @queue.push do (html) =>
                return (callback) => @scrapeHtml html, callback
            html = ""

        @inPorts.ignoreSelector.on "data", (data) =>
            @ignoreSelectors.push data

        super "ScrapeHtml"

    scrapeHtml: (html, callback) ->
        return callback null unless html.length > 0
        return callback null unless @textSelector.length > 0
        args =
            html: html,
            done: (err, win) =>
                if err
                    @outPorts.error.send err
                    @outPorts.error.disconnect()
                    return callback err
                win.$(ignore).remove() for ignore in @ignoreSelectors
                win.$(@textSelector).map (i,e) =>
                    @outPorts.out.beginGroup e.id if e.hasAttribute "id"
                    @outPorts.out.send win.$(e).text()
                    @outPorts.out.endGroup() if e.hasAttribute "id"
                callback null
        args[@jquerysrc] = @jquery
        jsdom.env args

exports.getComponent = -> new ScrapeHtml
