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

        html = ""
        @inPorts.in.on "connect", =>
            html = ""
        @inPorts.in.on "data", (data) =>
            html += data
        @inPorts.in.on "endgroup", =>
            @push @scrapeHtml, [html]
            html = ""
        @inPorts.in.on "disconnect", =>
            @push @scrapeHtml, [html]
            html = ""

        @inPorts.textSelector.on "data", (data) =>
            @textSelector = data
        @inPorts.textSelector.on "disconnect", =>
            @push @scrapeHtml, [html]
            html = ""

        @inPorts.ignoreSelector.on "data", (data) =>
            @ignoreSelectors.push data

        super "ScrapeHtml"

    scrapeHtml: (html, groups, callback) ->
        return callback() unless html.length > 0
        return callback() unless @textSelector.length > 0
        $ = cheerio.load html
        $(ignore).remove() for ignore in @ignoreSelectors
        @outPorts.out.beginGroup group for group in groups
        $(@textSelector).each (i,e) =>
            o = $(e)
            id = o.attr "id"
            @outPorts.out.beginGroup id if id?
            @outPorts.out.send decode o.text()
            @outPorts.out.endGroup() if id?
        @outPorts.out.endGroup() for group in groups
        callback()

exports.getComponent = -> new ScrapeHtml
