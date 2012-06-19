router = require "../src/components/TypeRouter"
socket = require "../src/lib/InternalSocket"

setupComponent = ->
    c = router.getComponent()
    ins = socket.createSocket()
    boo = socket.createSocket()
    num = socket.createSocket()
    str = socket.createSocket()
    arr = socket.createSocket()
    obj = socket.createSocket()
    nul = socket.createSocket()
    und = socket.createSocket()
    c.inPorts.in.attach ins
    c.outPorts.boolean.attach boo
    c.outPorts.number.attach num
    c.outPorts.string.attach str
    c.outPorts.array.attach arr
    c.outPorts.object.attach obj
    c.outPorts.null.attach nul
    c.outPorts.undefined.attach und
    [c, ins, boo, num, str, arr, obj, nul, und]

exports['test routing'] = (test) ->
    test.expect 7
    [c, ins, boo, num, str, arr, obj, nul, und] = setupComponent()
    boo.on 'data', (data) ->
        test.strictEqual data, false
    num.on 'data', (data) ->
        test.equal data, 3
    str.on 'data', (data) ->
        test.equal data, "foo"
    arr.on 'data', (data) ->
        test.deepEqual data, [7]
    obj.on 'data', (data) ->
        test.deepEqual data, {a:2}
    nul.on 'data', (data) ->
        test.ok data is null
    und.on 'data', (data) ->
        test.ok data is undefined
        test.done()
    ins.send false
    ins.send 3
    ins.send "foo"
    ins.send [7]
    ins.send {a:2}
    ins.send null
    ins.send undefined

