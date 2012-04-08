scrape = require "../src/components/ScrapeHtml"
socket = require "../src/lib/InternalSocket"

setupComponent = ->
    c = scrape.getComponent()
    ins = socket.createSocket()
    out = socket.createSocket()
    q = socket.createSocket()
    sat = socket.createSocket()
    emp = socket.createSocket()
    dra = socket.createSocket()
    c.inPorts.in.attach ins
    c.outPorts.out.attach out
    c.outPorts.queued.attach q
    c.outPorts.saturated.attach sat
    c.outPorts.empty.attach emp
    c.outPorts.drain.attach dra
    return [c, ins, out, q, sat, emp, dra]

exports["test change concurrency"] = (test) ->
    [c, ins, out, q, sat, emp, dra] = setupComponent()
    cc = socket.createSocket()
    s = socket.createSocket()
    c.inPorts.concurrency.attach cc
    c.inPorts.textSelector.attach s
    datas = []
    calls = []
    q.on "data", (data) -> calls.push "queued #{data}"
    sat.once "data", -> test.fail "should not get saturated"
    emp.on "data", -> calls.push "empty"
    out.on "data", (data) -> datas.push data
    dra.on "data", ->
        calls.push "drain"
        test.same datas, ["bar", "baz"]
        test.same calls, ["queued 1", "queued 2", "queued 3", "empty", "drain"]
        test.done()
    cc.send 4
    cc.disconnect()
    s.send "p.test"
    s.disconnect()
    ins.send '<div><p>foo</p><p class="test">ba'
    ins.send 'r</p><p class="test">baz</p></div>'
    ins.disconnect()

exports["test selector then html"] = (test) ->
    [c, ins, out, q, sat, emp, dra] = setupComponent()
    s = socket.createSocket()
    c.inPorts.textSelector.attach s
    expect = ["bar","baz"]
    out.once "begingroup", (group) ->
        test.fail "should not get groups without element ids"
    out.on "data", (data) ->
        test.equal data, expect.shift()
        test.done() if expect.length == 0
    s.send "p.test"
    s.disconnect()
    ins.send '<div><p>foo</p><p class="test">ba'
    ins.send 'r</p><p class="test">baz</p></div>'
    ins.disconnect()

exports["test html then selector"] = (test) ->
    [c, ins, out, q, sat, emp, dra] = setupComponent()
    s = socket.createSocket()
    c.inPorts.textSelector.attach s
    expect = ["bar","baz"]
    out.on "data", (data) ->
        test.equal data, expect.shift()
        test.done() if expect.length == 0
    ins.send '<div><p>foo</p><p class="test">ba'
    ins.send 'r</p><p class="test">baz</p></div>'
    ins.disconnect()
    s.send "p.test"
    s.disconnect()

exports["test ignore"] = (test) ->
    [c, ins, out, q, sat, emp, dra] = setupComponent()
    s = socket.createSocket()
    i = socket.createSocket()
    c.inPorts.textSelector.attach s
    c.inPorts.ignoreSelector.attach i
    expect = ["foo"]
    out.on "data", (data) ->
        test.equal data, expect.shift()
        test.done() if expect.length == 0
    i.send ".noise"
    i.send "#crap"
    i.disconnect()
    ins.send '<div><p class="test">foo</p><p id="crap" class="test">ba'
    ins.send 'r</p><p class="test noise">baz</p></div>'
    ins.disconnect()
    s.send "p.test"
    s.disconnect()

exports["test group by element id"] = (test) ->
    [c, ins, out, q, sat, emp, dra] = setupComponent()
    s = socket.createSocket()
    c.inPorts.textSelector.attach s
    expectevent = "begingroup"
    expectgroup = ["a","b"]
    out.on "begingroup", (group) ->
        test.equal "begingroup", expectevent
        test.equal group, expectgroup.shift()
        expectevent = "data"
    expectdata = ["bar","baz"]
    out.on "data", (data) ->
        test.equal "data", expectevent
        test.equal data, expectdata.shift()
        expectevent = "endgroup"
    out.on "endgroup", ->
        test.equal "endgroup", expectevent
        expectevent = "begingroup"
        test.done() if expectgroup.length == 0
    s.send "p.test"
    s.disconnect()
    ins.send '<div><p>foo</p><p id="a" class="test">ba'
    ins.send 'r</p><p id="b" class="test">baz</p></div>'
    ins.disconnect()
