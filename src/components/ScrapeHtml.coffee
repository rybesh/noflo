noflo = require "noflo"
cheerio = require "cheerio"
fs = require "fs"

decode = (str) ->
  return str unless str.indexOf "&" >= 0
  return str.replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&")

class ScrapeHtml extends noflo.QueueingComponent
    constructor: ->
        @textSelector = ""
        @ignoreSelectors = []

        @inPorts =
            in: new noflo.Port()
            textSelector: new noflo.Port()
            ignoreSelector: new noflo.ArrayPort()
        @outPorts =
            out: new noflo.Port()
            error: new noflo.Port()

        current_group = null
        html = ""
        @inPorts.in.on "connect", =>
            html = ""
        @inPorts.in.on "begingroup", (group) =>
            current_group = group
        @inPorts.in.on "data", (data) =>
            html += data
        @inPorts.in.on "endgroup", =>
            @push do (html, current_group) =>
                return (callback) => @scrapeHtml html, current_group, callback
            current_group = null
            html = ""
        @inPorts.in.on "disconnect", =>
            @push do (html, current_group) =>
                return (callback) => @scrapeHtml html, current_group, callback
            html = ""

        @inPorts.textSelector.on "data", (data) =>
            @textSelector = data
        @inPorts.textSelector.on "disconnect", =>
            @push do (html, current_group) =>
                return (callback) => @scrapeHtml html, current_group, callback
            html = ""

        @inPorts.ignoreSelector.on "data", (data) =>
            @ignoreSelectors.push data

        super "ScrapeHtml"

    doScrape: ->

    scrapeHtml: (html, group, callback) ->
        return callback() unless html.length > 0
        return callback() unless @textSelector.length > 0
        @outPorts.out.beginGroup group if group?
        $ = cheerio.load html
        $(ignore).remove() for ignore in @ignoreSelectors
        $(@textSelector).each (i,e) =>
            o = $(e)
            id = o.attr "id"
            @outPorts.out.beginGroup id if id?
            @outPorts.out.send decode o.text()
            @outPorts.out.endGroup() if id?
        @outPorts.out.endGroup group if group?
        callback()

exports.getComponent = -> new ScrapeHtml
