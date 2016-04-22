TarGz  = require 'tar.gz'
zipdir = require 'zip-dir'
path   = require 'path'
async  = require 'async'

class Bundler
  constructor: ({ @os, @buildDir, @fileName, @fileNameWithExt }) ->

  do: (tmpDir, callback) =>
    console.log "### bundling"
    destination = path.join @buildDir, "deploy", @fileNameWithExt
    bundleDir = path.join tmpDir, @fileName
    async.series [
      async.apply(@tarGz, {bundleDir, destination})
      async.apply(@zip, {bundleDir, destination})
    ], (error) =>
      return callback error if error?
      console.log '### bundled', destination.replace(@buildDir, ".")
      return callback null, destination

  tarGz: ({bundleDir, destination}, callback) =>
    return callback() if @os == "windows"
    console.log '### bundling tar.gz'
    new TarGz({}, {fromBase: true}).compress bundleDir, destination, callback

  zip: ({bundleDir, destination}, callback) =>
    return callback() if @os != "windows"
    console.log '### bundling zip'
    zipdir bundleDir, {saveTo: destination}, callback

module.exports = Bundler
