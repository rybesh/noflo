dupe = require "../src/components/DuplicateProperty"
socket = require "../src/lib/InternalSocket"

setupComponent = ->
    c = dupe.getComponent()
    ins = socket.createSocket()
    pro = socket.createSocket()
    sep = socket.createSocket()
    out = socket.createSocket()
    c.inPorts.in.attach ins
    c.inPorts.property.attach pro
    c.inPorts.separator.attach sep
    c.outPorts.out.attach out
    return [c, ins, pro, sep, out]

exports["test default"] = (test) ->
    [c, ins, pro, sep, out] = setupComponent()
    out.on "data", (data) ->
        test.same data, { a:1, b:2, c:3 }
        test.done()
    ins.send { a:1, b:2, c:3 }

exports["test dupe properties via map"] = (test) ->
    [c, ins, pro, sep, out] = setupComponent()
    out.on "data", (data) ->
        test.same data, { a:1, b:2, c:3, d:1, e:1, f:undefined }
        test.done()
    pro.send { d:"a", e:"d", f:"g" }
    ins.send { a:1, b:2, c:3 }

exports["test dupe properties via strings"] = (test) ->
    [c, ins, pro, sep, out] = setupComponent()
    out.on "data", (data) ->
        test.same data, { a:1, b:2, c:3, d:1, e:1, f:undefined }
        test.done()
    pro.send "d=a"
    pro.send "e=d"
    pro.send "f=g"
    ins.send { a:1, b:2, c:3 }

exports["test dupe property via concat"] = (test) ->
    [c, ins, pro, sep, out] = setupComponent()
    out.on "data", (data) ->
        test.same data, { a:1, b:2, c:3, d:"3/2/1" }
        test.done()
    pro.send "d=c=b=a"
    ins.send { a:1, b:2, c:3 }

exports["test modify property via concat"] = (test) ->
    [c, ins, pro, sep, out] = setupComponent()
    out.on "data", (data) ->
        test.same data, { a:1, b:2, c:"3/2/1" }
        test.done()
    pro.send "c=c=b=a"
    ins.send { a:1, b:2, c:3 }

exports["test change separator"] = (test) ->
    [c, ins, pro, sep, out] = setupComponent()
    out.on "data", (data) ->
        test.same data, { a:1, b:2, c:3, d:"3+2+1" }
        test.done()
    pro.send "d=c=b=a"
    sep.send "+"
    ins.send { a:1, b:2, c:3 }
