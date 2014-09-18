fuse4js = require 'fuse4js'
fs      = require 'fs'
_       = require 'lodash'

class FileSystem
  constructor: (meshblu, options={}) ->
    @meshblu     = meshblu
    @debug       = options.debug || false
    @mount_point = options.mount_point
    @handlers =
      getattr:  @getattr
      readdir:  @readdir
      open:     @open
      read:     @read
      write:    => @unimplimented('write')
      release:  @release
      create:   => @unimplimented('create')
      unlink:   => @unimplimented('unlink')
      rename:   => @unimplimented('rename')
      mkdir:    => @unimplimented('mkdir')
      rmdir:    => @unimplimented('rmdir')
      init:     @init
      destroy:  => @unimplimented('destroy')
      setxattr: => @unimplimented('setxattr')
      statfs:   @statfs

  getattr: (path, callback) =>
    if path == '/' || path == '/._.'
      return callback 0, size: 4096, mode: 0o40777

    callback 0, size: 8, mode: 0o100666

  init: (callback=->) =>
    callback()

  open: (path, flags, callback=->) =>
    callback 0

  read: (path, offset, len, buffer, fh, callback=->) =>
    err  = 0
    file = 'your mom'

    if offset < file.length
      max_bytes = file.length - offset
      if  len > max_bytes
        len = max_bytes

      data = file.substring offset, len
      buffer.write data, 0, len, 'ascii'
      err = len

    callback err

  readdir: (path, callback=->) =>
    @meshblu.mydevices {}, (response) =>
      devices = _.where response.devices, online: true
      callback 0, _.pluck(devices, 'uuid')

  release: (path, fh, callback=->) =>
    callback 0

  statfs: (callback=->) =>
    callback 0,
      bsize:   1000000
      frsize:  1000000
      blocks:  1000000
      bfree:   1000000
      bavail:  1000000
      files:   1000000
      ffree:   1000000
      favail:  1000000
      fsid:    1000000
      flag:    1000000
      namemax: 1000000

  start: (options={}) =>
    fuse4js.start @mount_point, @handlers, @debug, []

  unimplimented: (method_name) =>
    console.log "unimplemented: #{method_name}"
    throw new Error(method_name);


module.exports = FileSystem
