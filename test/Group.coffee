group = require "../src/components/Group"
socket = require "../src/lib/InternalSocket"

setupComponent = ->
  c = group.getComponent()
  ins = socket.createSocket()
  grp = socket.createSocket()
  out = socket.createSocket()
  c.inPorts.in.attach ins
  c.inPorts.group.attach grp
  c.outPorts.out.attach out
  return [c, ins, grp, out ]

exports["test default behavior"] = (test) ->
  test.expect 1
  [c, ins, grp, out] = setupComponent()
  output = []
  out.on "begingroup", (data) ->
    output.push "group #{data}"
  out.on "data", (data) ->
    output.push "out #{data}"
  out.on "endgroup", ->
    output.push "endgroup"
  out.on "disconnect", (data) ->
    test.same output, [
      "group A"
      "out 1"
      "endgroup"
      "out 2"
    ]
    test.done()
  ins.beginGroup "A"
  ins.send 1
  ins.endGroup()
  ins.send 2
  ins.disconnect()

exports["test 1 group"] = (test) ->
  test.expect 1
  [c, ins, grp, out] = setupComponent()
  output = []
  out.on "begingroup", (data) ->
    output.push "group #{data}"
  out.on "data", (data) ->
    output.push "out #{data}"
  out.on "endgroup", ->
    output.push "endgroup"
  out.on "disconnect", (data) ->
    test.same output, [
      "out 1"
      "group A"
      "out 2"
      "endgroup"
    ]
    test.done()
  ins.send 1
  grp.send "A"
  ins.send 2
  ins.disconnect()

exports["test nested groups"] = (test) ->
  test.expect 1
  [c, ins, grp, out] = setupComponent()
  output = []
  out.on "begingroup", (data) ->
    output.push "group #{data}"
  out.on "data", (data) ->
    output.push "out #{data}"
  out.on "endgroup", ->
    output.push "endgroup"
  out.on "disconnect", (data) ->
    test.same output, [
      "group A"
      "out 1"
      "group B"
      "out 2"
      "endgroup"
      "endgroup"
    ]
    test.done()
  ins.beginGroup "A"
  ins.send 1
  grp.send "B"
  ins.send 2
  ins.endGroup()
  ins.disconnect()

exports["test sequential groups"] = (test) ->
  test.expect 1
  [c, ins, grp, out] = setupComponent()
  output = []
  out.on "begingroup", (data) ->
    output.push "group #{data}"
  out.on "data", (data) ->
    output.push "out #{data}"
  out.on "endgroup", ->
    output.push "endgroup"
  out.on "disconnect", (data) ->
    test.same output, [
      "group A"
      "out 1"
      "endgroup"
      "group B"
      "out 2"
      "endgroup"
    ]
    test.done()
  grp.send "A"
  ins.send 1
  grp.send "B"
  ins.send 2
  ins.disconnect()
