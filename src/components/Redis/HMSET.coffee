noflo = require "noflo"
redis = require "redis"

class HMSET extends noflo.AsyncComponent
    description: "Stores incoming objects as Redis hashes"

    constructor: ->
        @prefix = null
        @id = "id"

        @client = redis.createClient()

        @inPorts =
            in: new noflo.Port()
            db: new noflo.Port()
            prefix: new noflo.Port()
            id: new noflo.Port()
        @outPorts =
            out: new noflo.Port()
            error: new noflo.Port()

        @inPorts.db.on "data", (data) =>
            @client.select data
        @inPorts.prefix.on "data", (data) =>
            @prefix = data
        @inPorts.id.on "data", (data) =>
            @id = data

        super()

    getID: (obj, callback) ->
        return callback null, String(obj[@id]) if @id of obj
        @client.incr @id, (err, res) =>
            callback err, String(res)

    getKey: (obj, callback) ->
        @getID obj, (err, id) =>
            return callback err if err?
            key = if @prefix? then "#{@prefix}:#{id}" else id
            callback null, key

    cleanUp: (callback) ->
        @client.quit -> callback()

    doAsync: (obj, callback) ->
        unless typeof obj == "object"
            return callback new Error "data must be an object"
        @getKey obj, (err, key) =>
            return callback err if err?
            @client.hmset key, obj, (err, res) =>
                return callback err if err?
                @outPorts.out.send key
                callback null

exports.getComponent = ->
    new HMSET()