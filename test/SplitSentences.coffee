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
    calls = []
    datas = []
    out.on "begingroup", (group) ->
        calls.push "begingroup #{group}"
    out.on "data", (data) ->
        calls.push "data"
        datas.push data
    out.on "endgroup", ->
        calls.push "endgroup"
        test.same calls, ["begingroup test", "data", "data", "endgroup"]
        test.same datas, [
          "One of Manila's most notorious jails is allowing inmates to handle cleavers and knives.",
          "Based on a reality show, it is meant to hone inmates' skills, keep them productive, and prepare them to return to the work force."
        ]
        test.done()
    ins.beginGroup "test"
    ins.send "One of Manila's most notorious jails is allowing inmates to hand"
    ins.send "le cleavers and knives. Based on a reality show, it is meant to "
    ins.send "hone inmates' skills, keep them productive, and prepare them to "
    ins.send "return to the work force."
    ins.endGroup()
    ins.disconnect()
