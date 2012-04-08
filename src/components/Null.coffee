noflo = require "noflo"
util = require "util"

class Null extends noflo.Component

    description: "This component simply ignores all input and sends no output"

    constructor: ->
        @inPorts =
            in: new noflo.ArrayPort()
        @outPorts = {}

exports.getComponent = -> new Null()
