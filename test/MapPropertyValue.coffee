mapper = require "../src/components/MapPropertyValue"
socket = require "../src/lib/InternalSocket"

setupComponent = ->
    c = mapper.getComponent()
    ins = socket.createSocket()
    map = socket.createSocket()
    reg = socket.createSocket()
    out = socket.createSocket()
    c.inPorts.in.attach ins
    c.inPorts.map.attach map
    c.inPorts.regexp.attach reg
    c.outPorts.out.attach out
    return [c, ins, map, reg, out]

exports["test regexp"] = (test) ->
    [c, ins, map, reg, out] = setupComponent()
    out.on "data", (data) ->
        test.same data, { path:"boo:biz-baz/6" }
        test.done()
    reg.send "path=.*/w/([^/]+)/s/(\\d+).*=boo:$1/$2"
    ins.send { path:"/foo/bar/w/biz-baz/s/6.txt" }
