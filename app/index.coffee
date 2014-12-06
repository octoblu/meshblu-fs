debug   = require('debug')('meshblu-fs:index')
Meshblu = require 'meshblu'
url     = require 'url'
_       = require 'lodash'
FileSystem = require './file_system'

class MeshbluFS
  constructor: (@options={}) ->
    {protocol, hostname, port} = url.parse @options.meshblu_uri
    @meshblu = Meshblu.createConnection
      protocol: protocol
      server: hostname
      port: port ? 80
      uuid: @options.uuid
      token: @options.token

    @file_system = new FileSystem @meshblu, @options

    @meshblu.on 'notReady', (error) =>
      console.error 'not ready', error

    @meshblu.on 'ready', =>
      debug 'ready'
      @meshblu.ready = true
      @refresh_devices()

    @meshblu.on 'config', (device) =>
      debug 'config'
      return if device.uuid == @options.uuid
      oldDevice = _.findWhere @file_system.devices, {uuid: device.uuid}

      if !oldDevice?
        if device.online
          @file_system.devices?.push device
        return

      if device.online
        return _.extend oldDevice, device
      else
        return @file_system.devices = _.without @file_system.devices, oldDevice

  refresh_devices: =>
    debug 'start @meshblu.mydevices'
    @meshblu.mydevices {}, (response) =>
      debug 'end @meshblu.mydevices'
      @file_system.devices = _.where response.devices, online: true
      @subscribe_to @file_system.devices

  start: =>
    @file_system.start()

  subscribe_to: (devices) =>
    _.each devices, (device) =>
      @meshblu.subscribe {uuid: device.uuid, token: device.token}

module.exports = MeshbluFS
