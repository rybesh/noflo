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
        @outPorts[port].beginGroup group if @outPorts[port].socket?

    @inPorts.in.on 'data', (data) =>
      @outPorts[(toString.call data).slice(8,-1).toLowerCase()].send data

    @inPorts.in.on 'endgroup', =>
      for port of @outPorts
        @outPorts[port].endGroup() if @outPorts[port].socket?

    @inPorts.in.on 'disconnect', =>
      for port of @outPorts
        @outPorts[port].disconnect() if @outPorts[port].socket?

exports.getComponent = -> new TypeRouter
