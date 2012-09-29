factory = require "../src/components/SaxParseXml"
socket = require "../src/lib/InternalSocket"

setupComponent = ->
  c = factory.getComponent()
  ins = socket.createSocket()
  acc = socket.createSocket()
  rej = socket.createSocket()
  opt = socket.createSocket()
  out = socket.createSocket()
  err = socket.createSocket()
  lod = socket.createSocket()
  c.inPorts.in.attach ins
  c.inPorts.accept.attach acc
  c.inPorts.reject.attach rej
  c.inPorts.options.attach opt
  c.outPorts.out.attach out
  c.outPorts.error.attach err
  c.outPorts.load.attach lod
  [c, ins, acc, rej, opt, out, err, lod]

exports['test default setup'] = (test) ->
  [c, ins, acc, rej, opt, out, err, lod] = setupComponent()
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
  [c, ins, acc, rej, opt, out, err, lod] = setupComponent()
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
  acc.send "bar"
  ins.beginGroup "foo"
  ins.send """<bar>
baz
</bar>
"""
  ins.endGroup()
  ins.disconnect()

exports['test trim'] = (test) ->
  [c, ins, acc, rej, opt, out, err, lod] = setupComponent()
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
      "baz"
      "endgroup"
      "load 0"
      "endgroup"
    ]
    test.done()
  err.once "data", (data) ->
    test.fail data
  lod.on "data", (load) ->
    data.push "load #{load}"
  opt.send {trim:true}
  acc.send "bar"
  ins.beginGroup "foo"
  ins.send """<bar>
baz
</bar>
"""
  ins.endGroup()
  ins.disconnect()

exports['test normalize'] = (test) ->
  [c, ins, acc, rej, opt, out, err, lod] = setupComponent()
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
      " baz baz baz "
      "endgroup"
      "load 0"
      "endgroup"
    ]
    test.done()
  err.once "data", (data) ->
    test.fail data
  lod.on "data", (load) ->
    data.push "load #{load}"
  opt.send {normalize:true}
  acc.send "bar"
  ins.beginGroup "foo"
  ins.send """<bar>
baz   baz  baz
</bar>
"""
  ins.endGroup()
  ins.disconnect()

exports['test reject'] = (test) ->
  [c, ins, acc, rej, opt, out, err, lod] = setupComponent()
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
      "begingroup yes"
      "the quick brown "
      "begingroup yes"
      "fox"
      "endgroup"
      "endgroup"
      "begingroup yes"
      "keep us together"
      "endgroup"
      "load 0"
      "endgroup"
    ]
    test.done()
  err.once "data", (data) ->
    test.fail data
  lod.on "data", (load) ->
    data.push "load #{load}"
  acc.send "yes"
  rej.send "no"
  ins.beginGroup "foo"
  ins.send """<doc>
<yes>the quick brown <no>fuzz <yes>fox</yes></no></yes>
<yes>keep us <no/>together</yes>
</doc>
"""
  ins.endGroup()
  ins.disconnect()

exports['test attributes'] = (test) ->
  [c, ins, acc, rej, opt, out, err, lod] = setupComponent()
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
      "begingroup marker"
      {time:1}
      "endgroup"
      "begingroup yes"
      "begingroup p"
      "the quick brown fox"
      "endgroup"
      "begingroup marker"
      {time:2}
      "endgroup"
      "begingroup p"
      "jumped over"
      "endgroup"
      "endgroup"
      "load 0"
      "endgroup"
    ]
    test.done()
  err.once "data", (data) ->
    test.fail data
  lod.on "data", (load) ->
    data.push "load #{load}"
  opt.send {trim:true}
  acc.send "marker"
  acc.send "yes"
  ins.beginGroup "foo"
  ins.send """<doc>
  <marker time="1"/>
  <yes>
    <p>the quick brown fox</p>
    <marker time="2"/>
    <p>jumped over</p>
  </yes>
</doc>
"""
  ins.endGroup()
  ins.disconnect()
