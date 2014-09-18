fuse4js = require 'fuse4js'
fs      = require 'fs'

class FileSystem
  initialize: (options={}) ->
    @debug       = options.debug
    @mount_point = options.mount_point
    @handlers =
      getattr: =>
      readdir: =>
      open: =>
      read: =>
      write: =>
      release: =>
      create: =>
      unlink: =>
      rename: =>
      mkdir: =>
      rmdir: =>
      init: =>
      destroy: =>
      setxattr: =>
      statfs: =>

  start: (options={}) =>
    fuse4js.start @mount_point, @handlers, @debug, {}
