program   = require 'commander'
fs        = require 'fs'
_         = require 'lodash'
pjson     = require '../package.json'
MeshbluFS = require './index'

class Command
  constructor: ->
    program
      .version pjson.version
      .option '-d, --debug',                'Enable Debug'
      .option '--meshblu-uri [uri]',        'URI for meshblu, defaults to ws://meshblu.octoblu.com'
      .option '-m, --mount-point [path]',   'Where to mount meshblu'
      .option '-u, --uuid [uuid]',          'User UUID'
      .option '-t, --token [token]',        'User Token'
      .option '-c, --config [config file]', 'Path to config file'
      .parse(process.argv);

    if program.config?
      _.extend program, JSON.parse(fs.readFileSync(program.config))

    {debug, meshbluUri, mountPoint, uuid, token} = program
    meshbluUri = meshbluUri ? 'ws://meshblu.octoblu.com'

    program.help() unless mountPoint && uuid && token

    @options =
      meshblu_uri: meshbluUri
      mount_point: mountPoint
      token:       token
      uuid:        uuid

  run: =>
    @meshblu_fs = new MeshbluFS @options
    @meshblu_fs.start()

command = new Command
command.run()
