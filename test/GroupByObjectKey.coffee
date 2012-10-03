group = require "../src/components/GroupByObjectKey"
socket = require "../src/lib/InternalSocket"

setupComponent = ->
  c = group.getComponent()
  ins = socket.createSocket()
  key = socket.createSocket()
  out = socket.createSocket()
  c.inPorts.in.attach ins
  c.inPorts.key.attach key
  c.outPorts.out.attach out
  return [c, ins, key, out ]

exports["test key first"] = (test) ->
  test.expect 1
  [c, ins, key, out] = setupComponent()
  output = []
  out.on "begingroup", (data) ->
    output.push "group #{data}"
  out.on "data", (data) ->
    output.push data
  out.on "endgroup", ->
    output.push "endgroup"
  out.on "disconnect", (data) ->
    test.same output, [
      "group bar"
      {foo:"bar"}
      "endgroup"
    ]
    test.done()
  key.send "foo"
  ins.send {foo:"bar"}
  ins.disconnect()

exports["test data first"] = (test) ->
  test.expect 1
  [c, ins, key, out] = setupComponent()
  output = []
  out.on "begingroup", (data) ->
    output.push "group #{data}"
  out.on "data", (data) ->
    output.push data
  out.on "endgroup", ->
    output.push "endgroup"
  out.on "disconnect", (data) ->
    test.same output, [
      "group bar"
      {foo:"bar"}
      "endgroup"
    ]
    test.done()
  ins.send {foo:"bar"}
  key.send "foo"
  ins.disconnect()

exports["test milestones 1"] = (test) ->
  test.expect 1
  [c, ins, key, out] = setupComponent()
  output = []
  out.on "begingroup", (data) ->
    output.push "group #{data}"
  out.on "data", (data) ->
    output.push data
  out.on "endgroup", ->
    output.push "endgroup"
  out.on "disconnect", (data) ->
    test.same output, [
      "group bar"
      {foo:"bar", kind:"open"}
      "group rab"
      {foo:"rab", kind:"open"}
      "baz"
      {foo:"rab", kind:"close"}
      "endgroup"
      {foo:"bar", kind:"close"}
      "endgroup"
    ]
    test.done()
  key.send {key:"foo", type:"kind", begin:"open", end:"close"}
  ins.send {foo:"bar", kind:"open"}
  ins.send {foo:"rab", kind:"open"}
  ins.send "baz"
  ins.send {foo:"rab", kind:"close"}
  ins.send {foo:"bar", kind:"close"}
  ins.disconnect()

exports["test milestones 2"] = (test) ->
  test.expect 1
  [c, ins, key, out] = setupComponent()
  output = []
  out.on "begingroup", (data) ->
    output.push "group #{data}"
  out.on "data", (data) ->
    output.push data
  out.on "endgroup", ->
    output.push "endgroup"
  out.on "disconnect", (data) ->
    test.same output, [
      "group spk1"
      {who:"spk1"}
      {said:"hi"}
      "endgroup"
      "group spk2"
      {who:"spk2"}
      "hello"
      "endgroup"
    ]
    test.done()
  key.send {key:"who"}
  ins.send {who:"spk1"}
  ins.send {said:"hi"}
  ins.send {who:"spk2"}
  ins.send "hello"
  ins.disconnect()

exports["test milestones 3"] = (test) ->
  test.expect 1
  [c, ins, key, out] = setupComponent()
  output = []
  out.on "begingroup", (data) ->
    output.push "group #{data}"
  out.on "data", (data) ->
    output.push data
  out.on "endgroup", ->
    output.push "endgroup"
  out.on "disconnect", (data) ->
    test.same output, [
      "group foo"
      {who:"foo"}
      {said:"hi"}
      "endgroup"
      "group A"
      {seg:"A", kind:"open"}
      "group bar"
      {who:"bar"}
      {said:"hey"}
      "endgroup"
      {seg:"A", kind:"close"}
      "endgroup"
    ]
    test.done()
  key.send [{key:"seg", type:"kind", begin:"open", end:"close"}, {key:"who"}]
  ins.send {who:"foo"}
  ins.send {said:"hi"}
  ins.send {seg:"A", kind:"open"}
  ins.send {who:"bar"}
  ins.send {said:"hey"}
  ins.send {seg:"A", kind:"close"}
  ins.disconnect()

exports["test milestones 3"] = (test) ->
  test.expect 1
  [c, ins, key, out] = setupComponent()
  output = []
  out.on "begingroup", (data) ->
    output.push "group #{data}"
  out.on "data", (data) ->
    output.push data
  out.on "endgroup", ->
    output.push "endgroup"
  out.on "disconnect", (data) ->
    test.same output, [
      "group foo"
      {who:"foo"}
      {said:"hi"}
      "endgroup"
      "group A"
      {seg:"A", kind:"open"}
      "group bar"
      {who:"bar"}
      "group hey"
      {fuk:"hey"}
      "endgroup"
      "endgroup"
      {seg:"A", kind:"close"}
      "endgroup"
    ]
    test.done()
  key.send [{key:"seg", type:"kind", begin:"open", end:"close"}, {key:"who"}, "fuk"]
  ins.send {who:"foo"}
  ins.send {said:"hi"}
  ins.send {seg:"A", kind:"open"}
  ins.send {who:"bar"}
  ins.send {fuk:"hey"}
  ins.send {seg:"A", kind:"close"}
  ins.disconnect()
