factory = require "../src/components/SaxParseXml"
socket = require "../src/lib/InternalSocket"

setupComponent = ->
  c = factory.getComponent()
  ins = socket.createSocket()
  tag = socket.createSocket()
  opt = socket.createSocket()
  out = socket.createSocket()
  err = socket.createSocket()
  lod = socket.createSocket()
  c.inPorts.in.attach ins
  c.inPorts.tags.attach tag
  c.inPorts.options.attach opt
  c.outPorts.out.attach out
  c.outPorts.error.attach err
  c.outPorts.load.attach lod
  [c, ins, tag, opt, out, err, lod]

exports['test default setup'] = (test) ->
  [c, ins, tag, opt, out, err, lod] = setupComponent()
  data = []
  test.expect 1
  out.on "begingroup", (group) ->
    data.push "begingroup #{group}"
  out.once "data", (data) ->
    test.fail "no data sent by default"
  out.on "endgroup", ->
    data.push "endgroup"
  out.on "disconnect", ->
    test.same data, ["begingroup foo","load 1","load 0","endgroup"]
    test.done()
  err.once "data", (data) ->
    test.fail data
  lod.on "data", (load) ->
    data.push "load #{load}"
  ins.beginGroup "foo"
  ins.send """<bar>
baz
</bar>
"""
  ins.endGroup()
  ins.disconnect()

exports['test capture element'] = (test) ->
  [c, ins, tag, opt, out, err, lod] = setupComponent()
  data = []
  test.expect 1
  out.on "begingroup", (group) ->
    data.push "begingroup #{group}"
  out.on "data", (d) ->
    data.push d
  out.on "endgroup", ->
    data.push "endgroup"
  out.on "disconnect", ->
    test.same data, [
      "begingroup foo"
      "load 1"
      "begingroup bar"
      "\nbaz\n"
      "endgroup"
      "load 0"
      "endgroup"
    ]
    test.done()
  err.once "data", (data) ->
    test.fail data
  lod.on "data", (load) ->
    data.push "load #{load}"
  tag.send "bar"
  ins.beginGroup "foo"
  ins.send """<bar>
baz
</bar>
"""
  ins.endGroup()
  ins.disconnect()
