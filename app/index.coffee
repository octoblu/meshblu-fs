debug   = require('debug')('meshblu-fs:index')
Meshblu = require 'meshblu'
url     = require 'url'
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

    @meshblu.on 'notReady', (error) =>
      console.error 'not ready', error

    @meshblu.on 'ready', =>
      @meshblu.ready = true
      debug 'ready'

  start: =>
    @file_system = new FileSystem @meshblu, @options
    @file_system.start()

module.exports = MeshbluFS
