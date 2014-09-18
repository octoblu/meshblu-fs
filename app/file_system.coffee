fuse4js = require 'fuse4js'
fs      = require 'fs'
_       = require 'lodash'

class FileSystem
  constructor: (meshblu, options={}) ->
    @meshblu     = meshblu
    @debug       = options.debug || false
    @mount_point = options.mount_point
    @buffers     = {}
    @handlers =
      getattr:  @getattr
      readdir:  @readdir
      open:     @open
      read:     @read
      write:    => @unimplimented('write')
      release:  @release
      flush:    => @unimplimented('flush')
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

    callback 0, size: 8096, mode: 0o100666

  init: (callback=->) =>
    callback()

  open: (path, flags, callback=->) =>
    uuid = path.replace '/', ''
    return callback -2 if /[g-zA-Z.]+/.test uuid

    @buffers[uuid] ?= ''
    @meshblu.subscribe uuid: uuid, =>
      callback 0

  read: (path, offset, len, buffer, fh, callback=->) =>
    err  = 0
    uuid = path.replace '/', ''
    device_buffer = @buffers[uuid]

    if offset < device_buffer.length
      max_bytes = device_buffer.length - offset
      if  len > max_bytes
        len = max_bytes

      data = device_buffer.substring offset, len
      buffer.write data, 0, len, 'ascii'
      err = len

    callback err

  readdir: (path, callback=->) =>
    return callback 0, [] unless @meshblu.ready
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
    @meshblu.on 'message', (message) =>
      @buffers[message.fromUUID] += JSON.stringify message

    fuse4js.start @mount_point, @handlers, @debug, []

  unimplimented: (method_name) =>
    console.error "unimplemented: #{method_name}"
    throw new Error(method_name);


module.exports = FileSystem
