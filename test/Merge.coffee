merge = require "../src/components/Merge"
socket = require "../src/lib/InternalSocket"

setupComponent = ->
    c = merge.getComponent()
    con = socket.createSocket()
    out = socket.createSocket()
    c.inPorts.mergeControlPackets.attach con
    c.outPorts.out.attach out
    [c, con, out]

exports['test default behavior'] = (test) ->
    test.expect 1
    [c, con, out] = setupComponent()
    actual = []
    out.on "connect", ->
        actual.push "connect"
    out.on "begingroup", (group) ->
        actual.push "group #{group}"
    out.on "endgroup", (group) ->
        actual.push "endgroup"
    out.on "data", (data) ->
        unless data is "end"
            return actual.push data
        test.same actual, [
            "connect"
            "connect"
            "group a"
            "group a"
            1
            2
            "endgroup"
            "endgroup"
            "disconnect"
            "disconnect"
            "connect"
        ]
        test.done()
    out.on "disconnect", ->
        actual.push "disconnect"
    in1 = socket.createSocket()
    in2 = socket.createSocket()
    c.inPorts.in.attach in1
    c.inPorts.in.attach in2
    in1.connect()
    in2.connect()
    in1.beginGroup "a"
    in2.beginGroup "a"
    in1.send 1
    in2.send 2
    in1.endGroup()
    in2.endGroup()
    in1.disconnect()
    in2.disconnect()
    in1.send "end"

exports['test merge 2'] = (test) ->
    test.expect 1
    [c, con, out] = setupComponent()
    actual = []
    out.on "connect", ->
        actual.push "connect"
    out.on "begingroup", (group) ->
        actual.push "group #{group}"
    out.on "endgroup", (group) ->
        actual.push "endgroup"
    out.on "data", (data) ->
        unless data is "end"
            return actual.push data
        test.same actual, [
            "connect"
            "group a"
            1
            2
            "endgroup"
            "disconnect"
            "connect"
        ]
        test.done()
    out.on "disconnect", ->
        actual.push "disconnect"
    con.send true # turn on merging of control packets
    in1 = socket.createSocket()
    in2 = socket.createSocket()
    c.inPorts.in.attach in1
    c.inPorts.in.attach in2
    in1.connect()
    in2.connect()
    in1.beginGroup "a"
    in2.beginGroup "a"
    in1.send 1
    in2.send 2
    in1.endGroup()
    in2.endGroup()
    in1.disconnect()
    in2.disconnect()
    in1.send "end"

exports['test merge 2 again'] = (test) ->
    test.expect 1
    [c, con, out] = setupComponent()
    actual = []
    out.on "connect", ->
        actual.push "connect"
    out.on "begingroup", (group) ->
        actual.push "group #{group}"
    out.on "endgroup", (group) ->
        actual.push "endgroup"
    out.on "data", (data) ->
        unless data is "end"
            return actual.push data
        test.same actual, [
            "connect"
            "group a"
            "group a"
            1
            2
            "endgroup"
            "endgroup"
            "disconnect"
            "connect"
        ]
        test.done()
    out.on "disconnect", ->
        actual.push "disconnect"
    con.send true # turn on merging of control packets
    in1 = socket.createSocket()
    in2 = socket.createSocket()
    c.inPorts.in.attach in1
    c.inPorts.in.attach in2
    in1.connect()
    in2.connect()
    in1.beginGroup "a"
    in2.beginGroup "a"
    in1.beginGroup "a"
    in1.send 1
    in2.send 2
    in1.endGroup()
    in2.endGroup()
    in1.endGroup()
    in1.disconnect()
    in2.disconnect()
    in1.send "end"

exports['test do not merge non-overlapping sequences'] = (test) ->
    test.expect 1
    [c, con, out] = setupComponent()
    actual = []
    out.on "connect", ->
        actual.push "connect"
    out.on "begingroup", (group) ->
        actual.push "group #{group}"
    out.on "endgroup", (group) ->
        actual.push "endgroup"
    out.on "data", (data) ->
        unless data is "end"
            return actual.push data
        test.same actual, [
            "connect"
            "group a"
            1
            "endgroup"
            "disconnect"
            "connect"
            "group a"
            2
            "endgroup"
            "disconnect"
            "connect"
            "group a"
            3
            "endgroup"
            "disconnect"
            "connect"
        ]
        test.done()
    out.on "disconnect", ->
        actual.push "disconnect"
    con.send true # turn on merging of control packets
    in1 = socket.createSocket()
    in2 = socket.createSocket()
    in3 = socket.createSocket()
    c.inPorts.in.attach in1
    c.inPorts.in.attach in2
    c.inPorts.in.attach in3
    in1.connect()
    in1.beginGroup "a"
    in1.send 1
    in1.endGroup()
    in1.disconnect()
    in2.connect()
    in2.beginGroup "a"
    in2.send 2
    in2.endGroup()
    in2.disconnect()
    in3.connect()
    in3.beginGroup "a"
    in3.send 3
    in3.endGroup()
    in3.disconnect()
    in1.send "end"

exports['test merge 3'] = (test) ->
    test.expect 1
    [c, con, out] = setupComponent()
    actual = []
    out.on "connect", ->
        actual.push "connect"
    out.on "begingroup", (group) ->
        actual.push "group #{group}"
    out.on "endgroup", (group) ->
        actual.push "endgroup"
    out.on "data", (data) ->
        unless data is "end"
            return actual.push data
        test.same actual, [
            "connect"
            "group a"
            1
            2
            3
            "endgroup"
            "disconnect"
            "connect"
        ]
        test.done()
    out.on "disconnect", ->
        actual.push "disconnect"
    con.send true # turn on merging of control packets
    in1 = socket.createSocket()
    in2 = socket.createSocket()
    in3 = socket.createSocket()
    c.inPorts.in.attach in1
    c.inPorts.in.attach in2
    c.inPorts.in.attach in3
    in1.connect()
    in2.connect()
    in3.connect()
    in1.beginGroup "a"
    in2.beginGroup "a"
    in3.beginGroup "a"
    in1.send 1
    in2.send 2
    in3.send 3
    in1.endGroup()
    in2.endGroup()
    in3.endGroup()
    in1.disconnect()
    in2.disconnect()
    in3.disconnect()
    in1.send "end"

exports['test do not merge nonredundant control packets'] = (test) ->
    test.expect 1
    [c, con, out] = setupComponent()
    actual = []
    out.on "connect", ->
        actual.push "connect"
    out.on "begingroup", (group) ->
        actual.push "group #{group}"
    out.on "endgroup", (group) ->
        actual.push "endgroup"
    out.on "data", (data) ->
        unless data is "end"
            return actual.push data
        test.same actual, [
            "connect"
            "group a"
            "group b"
            "group a"
            1
            2
            3
            "endgroup"
            "endgroup"
            "endgroup"
            "disconnect"
            "connect"
        ]
        test.done()
    out.on "disconnect", ->
        actual.push "disconnect"
    con.send true # turn on merging of control packets
    in1 = socket.createSocket()
    in2 = socket.createSocket()
    in3 = socket.createSocket()
    c.inPorts.in.attach in1
    c.inPorts.in.attach in2
    c.inPorts.in.attach in3
    in1.connect()
    in2.connect()
    in3.connect()
    in1.beginGroup "a"
    in2.beginGroup "b"
    in3.beginGroup "a"
    in1.send 1
    in2.send 2
    in3.send 3
    in1.endGroup()
    in2.endGroup()
    in3.endGroup()
    in1.disconnect()
    in2.disconnect()
    in3.disconnect()
    in1.send "end"


