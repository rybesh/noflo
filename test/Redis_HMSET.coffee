hmset = require "../src/components/Redis/HMSET"
socket = require "../src/lib/InternalSocket"
redis = require "redis"

TESTDB = 15

exports["setUp"] = (cb) ->
    @client = redis.createClient()
    @client.select TESTDB, =>
        @client.dbsize (err, res) ->
            throw err if err?
            throw new Error "test database has data in it!" if res > 0
            cb()

exports["tearDown"] = (cb) ->
    @client.flushdb (err) =>
        throw err if err?
        @client.quit -> cb()

setupComponent = ->
    c = hmset.getComponent()
    ins = socket.createSocket()
    dbn = socket.createSocket()
    out = socket.createSocket()
    lod = socket.createSocket()
    err = socket.createSocket()
    c.inPorts.in.attach ins
    c.inPorts.db.attach dbn
    c.outPorts.out.attach out
    c.outPorts.load.attach lod
    c.outPorts.error.attach err
    dbn.send TESTDB
    return [c, ins, out, lod, err]

exports["test send non-object"] = (test) ->
    [c, ins, out, lod, err] = setupComponent()
    err.once "data", (err) ->
        test.equal err.message, "data must be an object"
        test.done()
    ins.send "foobar"
    ins.disconnect()

exports["test default behavior"] = (test) ->
    [c, ins, out, lod, err] = setupComponent()
    obj =
        foo: "bar"
        biz: 69
    err.once "data", (err) ->
        test.fail err.message
        test.done()
    out.on "data", (key) =>
        # by default, ID property is "id"
        # if no such property on object, INCR a Redis string
        @client.get "id", (err, res) =>
            # by default, there is no prefix
            test.equal res, key
            @client.hgetall key, (err, res) ->
                # note conversion of number value to string
                test.same res, { foo: "bar", biz: "69" }
                test.done()
    ins.send obj
    ins.disconnect()

exports["test specify prefix"] = (test) ->
    [c, ins, out, lod, err] = setupComponent()
    pre = socket.createSocket()
    c.inPorts.prefix.attach pre
    obj =
        foo: "bar"
        biz: 69
    err.once "data", (err) ->
        test.fail err.message
        test.done()
    out.on "data", (key) =>
        # by default, ID property is "id"
        # if no such property on object, INCR a Redis string
        @client.get "id", (err, res) =>
            test.equal "test:#{res}", key
            @client.hgetall key, (err, res) ->
                # note conversion of number value to string
                test.same res,  { foo: "bar", biz: "69" }
                test.done()
    pre.send "test"
    ins.send obj
    ins.disconnect()

exports["test specify ID property"] = (test) ->
    [c, ins, out, lod, err] = setupComponent()
    idp = socket.createSocket()
    c.inPorts.id.attach idp
    obj =
        foo: "bar"
        biz: 69
    err.once "data", (err) ->
        test.fail err.message
        test.done()
    out.on "data", (key) =>
        # if no such property on object, INCR a Redis string
        @client.get "myid", (err, res) =>
            # by default, there is no prefix
            test.equal res, key
            @client.hgetall key, (err, res) ->
                # note conversion of number value to string
                test.same res,  { foo: "bar", biz: "69" }
                test.done()
    idp.send "myid"
    ins.send obj
    ins.disconnect()

exports["test specify obj property as ID"] = (test) ->
    [c, ins, out, lod, err] = setupComponent()
    idp = socket.createSocket()
    c.inPorts.id.attach idp
    obj =
        foo: "bar"
        biz: 69
    err.once "data", (err) ->
        test.fail err.message
        test.done()
    out.on "data", (key) =>
        @client.get "biz", (err, res) =>
            test.ok !res?, "should not create INCR value"
            # by default, there is no prefix
            test.equal obj.biz, key
            @client.hgetall key, (err, res) ->
                # note conversion of number value to string
                test.same res,  { foo: "bar", biz: "69" }
                test.done()
    idp.send "biz"
    ins.send obj
    ins.disconnect()

exports["test specify both prefix and obj property as ID"] = (test) ->
    [c, ins, out, lod, err] = setupComponent()
    pre = socket.createSocket()
    idp = socket.createSocket()
    c.inPorts.prefix.attach pre
    c.inPorts.id.attach idp
    obj =
        foo: "bar"
        biz: 69
    err.once "data", (err) ->
        test.fail err.message
        test.done()
    out.on "data", (key) =>
        @client.get "biz", (err, res) =>
            test.ok !res?, "should not create INCR value"
            test.equal "test:#{obj.biz}", key
            @client.hgetall key, (err, res) ->
                # note conversion of number value to string
                test.same res,  { foo: "bar", biz: "69" }
                test.done()
    pre.send "test"
    idp.send "biz"
    ins.send obj
    ins.disconnect()

# todo: add tests for specifying properties to index for lookups