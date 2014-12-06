fuse4js = require 'fuse4js'
fs      = require 'fs'
_       = require 'lodash'
debug   = require('debug')('meshblu-fs:file_system')

FILE_MODES =
  directory: 0o40777
  file:      0o100666

class FileSystem
  constructor: (meshblu, options={}) ->
    @meshblu        = meshblu
    @debug          = options.debug || false
    @mount_point    = options.mount_point
    @devices        = {}
    @input_buffers  = {}
    @output_buffers = {}
    @subscribe      = _.debounce @subscribe, 5000, true
    @unsubscribe    = _.debounce @unsubscribe, 5000
    @handlers =
      getattr:  @getattr
      readdir:  @readdir
      open:     @open
      read:     @read
      write:    @write
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

  add_or_update_device: (device) =>
    old_device = @devices[device.uuid]
    if old_device?
      _.extend oldDevice, device
    else
      @file_system.devices?.push device

  getattr: (path, callback) =>
    debug 'getattr', path
    if path == '/' || path == '/._.'
      return callback 0, size: 4096, mode: FILE_MODES.directory

    uuid = path.replace '/', ''
    return callback 0, size: 0, mode: FILE_MODES.file unless /[0-9a-f\-]+/.test uuid

    size = _.size JSON.stringify @devices[uuid]
    debug 'got size', size, JSON.stringify(@devices[uuid])
    callback 0, size: size, mode: FILE_MODES.file, mtime: new Date()

  init: (callback=->) =>
    callback()

  open: (path, flags, callback=->) =>
    debug 'open', path
    uuid = path.replace '/', ''
    return callback -2 if /[g-zA-Z.]+/.test uuid

    # @subscribe uuid
    @devices[uuid] ?= ''
    callback 0

  read: (path, offset, len, buffer, fh, callback=->) =>
    debug 'read', path, offset, len
    err  = 0
    uuid = path.replace '/', ''
    device_buffer = JSON.stringify @devices[uuid]

    if offset < device_buffer.length
      max_bytes = device_buffer.length - offset
      if len > max_bytes
        len = max_bytes

      data = device_buffer.substring offset, len
      debug 'buffer.write', data, 0, len, 'ascii'
      buffer.write data, 0, len, 'ascii'
      err = len

    callback err

  readdir: (path, callback=->) =>
    debug 'readdir'
    return callback 0, [] unless @meshblu.ready
    callback 0, _.pluck(_.values(@devices), 'uuid')

  release: (path, fh, callback=->) =>
    debug 'release', path
    uuid = path.replace '/', ''
    return callback 0 if /[g-zA-Z.]+/.test uuid

    # @unsubscribe uuid
    callback 0

  set_devices: (devices) =>
    _.each devices, (device) =>
      @devices[device.uuid] = device

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
      @input_buffers[message.fromUuid] ?= ''
      @input_buffers[message.fromUuid] += "#{JSON.stringify message}\n"

    fuse4js.start @mount_point, @handlers, @debug, []

  write: (path, offset, len, buffer, fh, callback=->) =>
    uuid = path.replace '/', ''
    return callback 0 if /[g-zA-Z.]+/.test uuid

    message_string = buffer.toString()
    @output_buffers[uuid] ?= ''

    _.each message_string, (character) =>
      @output_buffers[uuid] += character
      try
        @meshblu.message JSON.parse @output_buffers[uuid]
        @output_buffers[uuid] = ''

    callback _.size message_string

  unimplimented: (method_name) =>
    console.error "unimplemented: #{method_name}"
    throw new Error(method_name);

  subscribe: (uuid) =>
    # debounced by constructor
    console.error 'subscribe: ', uuid
    @meshblu.subscribe uuid: uuid, ->

  unsubscribe: (uuid) =>
    # debounced by constructor
    console.error 'unsubscribe: ', uuid
    @meshblu.unsubscribe uuid: uuid, =>
      @input_buffers[uuid] = ''

module.exports = FileSystem
