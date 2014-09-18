program    = require 'commander'
FileSystem = require './file_system'
pjson      = require '../package.json'

class Command
  constructor: ->
    program
      .version pjson.version
      .option '-d, --debug',              'Enable Debug'
      .option '-m, --mount-point [path]', 'Where to mount meshblu'
      .option '-u, --uuid [uuid]',        'User UUID'
      .option '-t, --token [token]',      'User Token'
      .parse(process.argv);

    {mountPoint, @uuid, @token, @debug} = program
    @mount_point = mountPoint
    program.help() unless @mount_point && @uuid && @token

  run: =>
    file_system = new FileSystem
      debug:       @debug
      mount_point: @mount_point
      token:       @token
      uuid:        @uuid
    file_system.start()

command = new Command
command.run()
