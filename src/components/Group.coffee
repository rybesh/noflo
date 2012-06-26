noflo = require "noflo"

class Group extends noflo.Component
  constructor: ->
    @inPorts =
      in: new noflo.ArrayPort
      group: new noflo.ArrayPort
    @outPorts =
      out: new noflo.Port

    group = null

    @inPorts.in.on "begingroup", (group) =>
      @outPorts.out.beginGroup group
    @inPorts.in.on "data", (data) =>
      @outPorts.out.send data
    @inPorts.in.on "endgroup", =>
      @outPorts.out.endGroup()
    @inPorts.in.on "disconnect", =>
      @outPorts.out.endGroup() if group?
      @outPorts.out.disconnect()
      group = null

    @inPorts.group.on "data", (data) =>
      @outPorts.out.endGroup() if group?
      @outPorts.out.beginGroup data
      group = data

exports.getComponent = -> new Group
