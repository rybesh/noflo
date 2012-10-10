collect = require "../src/components/CollectGroups"
socket = require "../src/lib/InternalSocket"

setupComponent = ->
    c = collect.getComponent()
    ins = socket.createSocket()
    grp = socket.createSocket()
    out = socket.createSocket()
    c.inPorts.in.attach ins
    c.inPorts.groups.attach grp
    c.outPorts.out.attach out
    return [c, ins, grp, out]

exports["test no groups"] = (test) ->
    [c, ins, grp, out] = setupComponent()
    output = []
    out.on "data", (data) ->
        output.push data
    out.once "disconnect", ->
        test.same output, [{ $data: ["a","b","c"] }]
        test.done()
    ins.send "a"
    ins.send "b"
    ins.send "c"
    ins.disconnect()

exports["test one group"] = (test) ->
    [c, ins, grp, out] = setupComponent()
    output = []
    expect =
        g1:
            $data: ["a","b"]
        $data: ["c"]
    out.on "data", (data) ->
        output.push data
    out.once "disconnect", ->
        test.same output, [expect]
        test.done()
    ins.beginGroup "g1"
    ins.send "a"
    ins.send "b"
    ins.endGroup()
    ins.send "c"
    ins.disconnect()

exports["test group named $data"] = (test) ->
    [c, ins, grp, out] = setupComponent()
    test.throws (-> ins.beginGroup "$data"), "groups cannot be named '$data'"
    test.done()

exports["test two groups"] = (test) ->
    [c, ins, grp, out] = setupComponent()
    output = []
    expect =
        g1:
            $data: ["a","b"]
        g2:
            $data: ["c","d"]
    out.on "data", (data) ->
        output.push data
    out.once "disconnect", ->
        test.same output, [expect]
        test.done()
    ins.beginGroup "g1"
    ins.send "a"
    ins.send "b"
    ins.endGroup()
    ins.beginGroup "g2"
    ins.send "c"
    ins.send "d"
    ins.endGroup()
    ins.disconnect()

exports["test collect specified groups"] = (test) ->
    [c, ins, grp, out] = setupComponent()
    output = []
    out.on "begingroup", (data) ->
        output.push "begingroup #{data}"
    out.on "data", (data) ->
        output.push data
    out.on "endgroup", ->
        output.push "endgroup"
    out.once "disconnect", ->
        test.same output, [
            {g1: {$data: ["a","b"]}}
            "begingroup g2"
            "c"
            "d"
            "endgroup"
            {g3: {$data: ["e","f"]}}
        ]
        test.done()
    grp.send ["g1","g3"]
    ins.beginGroup "g1"
    ins.send "a"
    ins.send "b"
    ins.endGroup()
    ins.beginGroup "g2"
    ins.send "c"
    ins.send "d"
    ins.endGroup()
    ins.beginGroup "g3"
    ins.send "e"
    ins.send "f"
    ins.endGroup()
    ins.disconnect()

exports["test two groups with same name"] = (test) ->
    [c, ins, grp, out] = setupComponent()
    output = []
    expect =
        g1: [ { $data: ["a","b"] }, { $data: ["c","d"] } ]
    out.on "data", (data) ->
        output.push data
    out.once "disconnect", ->
        test.same output, [expect]
        test.done()
    ins.beginGroup "g1"
    ins.send "a"
    ins.send "b"
    ins.endGroup()
    ins.beginGroup "g1"
    ins.send "c"
    ins.send "d"
    ins.endGroup()
    ins.disconnect()

exports["test nested groups"] = (test) ->
    [c, ins, grp, out] = setupComponent()
    output = []
    expect =
        g1:
            $data: ["a","b"]
            g2:
                $data: ["c","d"]
    out.on "data", (data) ->
        output.push data
    out.once "disconnect", ->
        test.same output, [expect]
        test.done()
    ins.beginGroup "g1"
    ins.send "a"
    ins.beginGroup "g2"
    ins.send "c"
    ins.send "d"
    ins.endGroup()
    ins.send "b"
    ins.endGroup()
    ins.disconnect()

exports["test object data"] = (test) ->
    [c, ins, grp, out] = setupComponent()
    output = []
    expect =
        g1:
            $data: [ {a:1,b:2}, {b:3,c:4} ]
    out.on "data", (data) ->
        output.push data
    out.once "disconnect", ->
        test.same output, [expect]
        test.done()
    ins.beginGroup "g1"
    ins.send {a:1,b:2}
    ins.send {b:3,c:4}
    ins.endGroup()
    ins.disconnect()

exports["test array data"] = (test) ->
    [c, ins, grp, out] = setupComponent()
    output = []
    expect =
        g1:
            $data: [ ["a","b"], ["c","d"] ]
    out.on "data", (data) ->
        output.push data
    out.once "disconnect", ->
        test.same output, [expect]
        test.done()
    ins.beginGroup "g1"
    ins.send ["a","b"]
    ins.send ["c","d"]
    ins.endGroup()
    ins.disconnect()
