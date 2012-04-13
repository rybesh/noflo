# The ReadFile component receives a filename on the in port, and
# sends the contents of the specified file to the out port. The filename
# is used to create a named group around the file contents data. In case
# of errors the error message will be sent to the error port.

fs = require "fs"
noflo = require "noflo"

class ReadFile extends noflo.QueueingComponent
    constructor: ->
        @inPorts =
            in: new noflo.Port()
        @outPorts =
            out: new noflo.Port()
            error: new noflo.Port()

        @inPorts.in.on "data", (data) =>
            @push @readFile, [data]

        super "ReadFile"

    readFile: (fileName, callback) ->
        fs.readFile fileName, "utf-8", (err, data) =>
            if err
                @outPorts.error.send err
                @outPorts.error.disconnect()
                return callback err
            @outPorts.out.beginGroup fileName
            @outPorts.out.send data
            @outPorts.out.endGroup()
            @outPorts.out.disconnect()
            callback()

exports.getComponent = ->
    new ReadFile()
