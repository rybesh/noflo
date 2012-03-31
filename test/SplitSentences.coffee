split = require "../src/components/SplitSentences"
socket = require "../src/lib/InternalSocket"

setupComponent = ->
    c = split.getComponent()
    ins = socket.createSocket()
    out = socket.createSocket()
    err = socket.createSocket()
    c.inPorts.in.attach ins
    c.outPorts.out.attach out
    c.outPorts.error.attach err
    return [c, ins, out, err]

exports["test splitting grouped text"] = (test) ->
    [c, ins, out, err] = setupComponent()
    err.once "data", (err) ->
        test.fail err
        test.done()
    expectevent = "begingroup"
    expectgroup = ["test"]
    out.on "begingroup", (group) ->
        test.equal "begingroup", expectevent
        test.equal group, expectgroup.shift()
        expectevent = "data"
    expectdata = [
        "One of Manila's most notorious jails is allowing inmates to handle cleavers and knives.",
        "Based on a reality show, it is meant to hone inmates' skills, keep them productive, and prepare them to return to the work force."
    ]
    out.on "data", (data) ->
        test.equal "data", expectevent
        test.equal data, expectdata.shift()
        expectevent = "endgroup" if expectdata.length == 0
    out.on "endgroup", ->
        test.equal "endgroup", expectevent
        expectevent = "begingroup"
        test.done() if expectgroup.length == 0
    ins.beginGroup "test"
    ins.send "One of Manila's most notorious jails is allowing inmates to hand"
    ins.send "le cleavers and knives. Based on a reality show, it is meant to "
    ins.send "hone inmates' skills, keep them productive, and prepare them to "
    ins.send "return to the work force."
    ins.endGroup()
    ins.disconnect()
