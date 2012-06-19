dedupe = require "../src/components/DedupeGroups"
socket = require "../src/lib/InternalSocket"

setupComponent = ->
    c = dedupe.getComponent()
    ins = socket.createSocket()
    out = socket.createSocket()
    c.inPorts.in.attach ins
    c.outPorts.out.attach out
    [c, ins, out]

exports['test no dupes'] = (test) ->
    test.expect 1
    [c, ins, out] = setupComponent()
    actual = []
    out.on "begingroup", (group) ->
        actual.push "group #{group}"
    out.on "endgroup", (group) ->
        actual.push "endgroup"
    out.on "data", (data) ->
        actual.push data
    out.on "disconnect", ->
        test.same actual, [
            "group a"
            "group b"
            "group a"
            1
            "endgroup"
            "endgroup"
            "endgroup"
        ]
        test.done()
    ins.beginGroup "a"
    ins.beginGroup "b"
    ins.beginGroup "a"
    ins.send 1
    ins.endGroup()
    ins.endGroup()
    ins.endGroup()
    ins.disconnect()

exports['test dupes 2'] = (test) ->
    test.expect 1
    [c, ins, out] = setupComponent()
    actual = []
    out.on "begingroup", (group) ->
        actual.push "group #{group}"
    out.on "endgroup", (group) ->
        actual.push "endgroup"
    out.on "data", (data) ->
        actual.push data
    out.on "disconnect", ->
        test.same actual, [
            "group a"
            "group b"
            1
            "endgroup"
            "endgroup"
        ]
        test.done()
    ins.beginGroup "a"
    ins.beginGroup "b"
    ins.beginGroup "b"
    ins.send 1
    ins.endGroup()
    ins.endGroup()
    ins.endGroup()
    ins.disconnect()

exports['test dupes 1'] = (test) ->
    test.expect 1
    [c, ins, out] = setupComponent()
    actual = []
    out.on "begingroup", (group) ->
        actual.push "group #{group}"
    out.on "endgroup", (group) ->
        actual.push "endgroup"
    out.on "data", (data) ->
        actual.push data
    out.on "disconnect", ->
        test.same actual, [
            "group b"
            "group a"
            1
            "endgroup"
            "endgroup"
        ]
        test.done()
    ins.beginGroup "b"
    ins.beginGroup "b"
    ins.beginGroup "a"
    ins.send 1
    ins.endGroup()
    ins.endGroup()
    ins.endGroup()
    ins.disconnect()
