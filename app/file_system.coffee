fuse4js = require 'fuse4js'
fs      = require 'fs'

class FileSystem
  constructor: (options={}) ->
    @debug       = options.debug || false
    @mount_point = options.mount_point
    @uuid        = options.uuid
    @token       = options.token
    @handlers =
      getattr:  ->
      readdir:  ->
      open:     ->
      read:     ->
      write:    ->
      release:  ->
      create:   ->
      unlink:   ->
      rename:   ->
      mkdir:    ->
      rmdir:    ->
      init:     ->
      destroy:  ->
      setxattr: ->
      statfs:   ->

  start: (options={}) =>
    fuse4js.start @mount_point, @handlers, @debug, []

module.exports = FileSystem
