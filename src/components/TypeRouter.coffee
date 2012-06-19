noflo = require 'noflo'

class TypeRouter extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.ArrayPort
    @outPorts =
      boolean: new noflo.Port
      number: new noflo.Port
      string: new noflo.Port
      array: new noflo.Port
      object: new noflo.Port
      null: new noflo.Port
      undefined: new noflo.Port

    @inPorts.in.on 'begingroup', (group) =>
      for port of @outPorts
        @outPorts[port].beginGroup group

    @inPorts.in.on 'data', (data) =>
      @outPorts[(toString.call data).slice(8,-1).toLowerCase()].send data

    @inPorts.in.on 'endgroup', =>
      for port of @outPorts
        @outPorts[port].endGroup()

    @inPorts.in.on 'disconnect', =>
      for port of @outPorts
        @outPorts[port].disconnect()

exports.getComponent = -> new TypeRouter
