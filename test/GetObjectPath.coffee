getpath = require "../src/components/GetObjectPath"
socket = require "../src/lib/InternalSocket"

setupComponent = ->
    c = getpath.getComponent()
    ins = socket.createSocket()
    out = socket.createSocket()
    err = socket.createSocket()
    c.inPorts.in.attach ins
    c.outPorts.out.attach out
    c.outPorts.error.attach err
    return [c, ins, out, err]

o =
    store:
        book: [
            {
            category: "reference"
            author: "Nigel Rees"
            title: "Sayings of the Century"
            price: 8.95
            }
            {
            category: "fiction"
            author: "Evelyn Waugh"
            title: "Sword of Honour"
            price: 12.99
            }
            {
            category: "fiction"
            author: "Herman Melville"
            title: "Moby Dick"
            isbn: "0-553-21311-3"
            price: 8.99
            }
            {
            category: "fiction"
            author: "J. R. R. Tolkien"
            title: "The Lord of the Rings"
            isbn: "0-395-19395-8"
            price: 22.99
            }
        ]
        bicycle:
            color: "red"
            price: 19.95

exports["test path then object"] = (test) ->
    [c, ins, out, err] = setupComponent()
    s = socket.createSocket()
    c.inPorts.path.attach s
    calls = []
    err.once "data", (data) ->
        test.fail data
    out.on "begingroup", (group) ->
        calls.push "begingroup #{group}"
    out.on "data", (data) ->
        calls.push data
    out.on "endgroup", ->
        calls.push "endgroup"
    out.once "disconnect", ->
        test.same calls,  [
            "begingroup groop"
            {
                category: "reference"
                author: "Nigel Rees"
                title: "Sayings of the Century"
                price: 8.95
            }
            {
                category: "fiction"
                author: "Herman Melville"
                title: "Moby Dick"
                isbn: "0-553-21311-3"
                price: 8.99
            }
            "endgroup"
        ]
        test.done()
    s.send "$..book[?(@.price<10)]"
    s.disconnect()
    ins.beginGroup "groop"
    ins.send o
    ins.endGroup()
    ins.disconnect()

exports["test object then path"] = (test) ->
    [c, ins, out, err] = setupComponent()
    s = socket.createSocket()
    c.inPorts.path.attach s
    calls = []
    err.once "data", (data) ->
        test.fail data
    out.on "begingroup", (group) ->
        calls.push "begingroup #{group}"
    out.on "data", (data) ->
        calls.push data
    out.on "endgroup", ->
        calls.push "endgroup"
    out.once "disconnect", ->
        test.same calls,  [
            "begingroup groop"
            {
                category: "reference"
                author: "Nigel Rees"
                title: "Sayings of the Century"
                price: 8.95
            }
            {
                category: "fiction"
                author: "Herman Melville"
                title: "Moby Dick"
                isbn: "0-553-21311-3"
                price: 8.99
            }
            "endgroup"
        ]
        test.done()
    ins.beginGroup "groop"
    ins.send o
    ins.endGroup()
    ins.disconnect()
    s.send "$..book[?(@.price<10)]"
    s.disconnect()

exports["test bogus path"] = (test) ->
    [c, ins, out, err] = setupComponent()
    s = socket.createSocket()
    c.inPorts.path.attach s
    calls = []
    err.once "data", (data) ->
        test.fail data
    out.on "begingroup", (group) ->
        calls.push "begingroup #{group}"
    out.on "data", (data) ->
        calls.push data
    out.on "endgroup", ->
        calls.push "endgroup"
    out.once "disconnect", ->
        test.same calls,  [
            "begingroup groop",
            "endgroup" ]
        test.done()
    s.send "$.bogus"
    s.disconnect()
    ins.beginGroup "groop"
    ins.send o
    ins.endGroup()
    ins.disconnect()

exports["test invalid path"] = (test) ->
    [c, ins, out, err] = setupComponent()
    s = socket.createSocket()
    c.inPorts.path.attach s
    err.once "data", (data) ->
        test.equal data, "invalid path: invalid"
        test.done()
    s.send "invalid"
    s.disconnect()
    ins.beginGroup "groop"
    ins.send o
    ins.endGroup()
    ins.disconnect()



