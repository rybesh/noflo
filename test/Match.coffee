match = require "../src/components/Match"
socket = require "../src/lib/InternalSocket"

setupComponent = ->
    c = match.getComponent()
    ins = socket.createSocket()
    reg = socket.createSocket()
    out = socket.createSocket()
    c.inPorts.in.attach ins
    c.inPorts.regex.attach reg
    c.outPorts.out.attach out
    return [c, ins, reg, out ]

exports["test default behavior"] = (test) ->
    test.expect 1
    [c, ins, reg, out] = setupComponent()
    output = []
    out.on "data", (data) ->
        output.push "out #{data}"
    out.on "disconnect", ->
        test.same output, [
            "out apple"
            "out banana"
            "out brain"
        ]
        test.done()
    ins.send "apple"
    ins.send "banana"
    ins.send "brain"
    out.disconnect()

exports["test one regex"] = (test) ->
    test.expect 1
    [c, ins, reg, out] = setupComponent()
    output = []
    for i in [0]
        m = socket.createSocket()
        do (m, i) ->
            m.on "data", (data) ->
                output.push "match #{i} #{data}"
        c.outPorts.match.attach m
    out.on "data", (data) ->
        output.push "out #{data}"
    out.on "disconnect", ->
        test.same output, [
            "match 0 apple"
            "out banana"
            "out brain"
        ]
        test.done()
    reg.send "^a"
    ins.send "apple"
    ins.send "banana"
    ins.send "brain"
    out.disconnect()

exports["test two regexes"] = (test) ->
    test.expect 1
    [c, ins, reg, out] = setupComponent()
    output = []
    for i in [0,1]
        m = socket.createSocket()
        do (m, i) ->
            m.on "data", (data) ->
                output.push "match #{i} #{data}"
        c.outPorts.match.attach m
    out.on "data", (data) ->
        output.push "out #{data}"
    out.on "disconnect", ->
        test.same output, [
            "match 0 apple"
            "match 1 banana"
            "out brain"
        ]
        test.done()
    reg.send "^a"
    reg.send "^ba"
    ins.send "apple"
    ins.send "banana"
    ins.send "brain"
    out.disconnect()

exports["test matches > 1"] = (test) ->
    test.expect 1
    [c, ins, reg, out] = setupComponent()
    output = []
    for i in [0,1]
        m = socket.createSocket()
        do (m, i) ->
            m.on "data", (data) ->
                output.push "match #{i} #{data}"
        c.outPorts.match.attach m
    out.on "data", (data) ->
        output.push "out #{data}"
    out.on "disconnect", ->
        test.same output, [
            "match 1 apple"
            "match 0 applebrain"
            "match 1 applebrain"
            "match 0 brain"
        ]
        test.done()
    reg.send "brain$"
    reg.send "^apple"
    ins.send "apple"
    ins.send "applebrain"
    ins.send "brain"
    out.disconnect()




