_             = require 'lodash'
fs            = require 'fs-extra'
path          = require 'path'
temp          = require 'temp'
async         = require 'async'
Bundler       = require './bundler'
Downloader    = require './downloader'

class Packager
  constructor: (@options) ->
    @bundler = new Bundler @options
    @downloader = new Downloader @options

  copyToTemp: (tmpDir, callback) =>
    console.log '### copying to temp'
    { buildDir, fileName } = @options

    filter = (filePath) =>
      relativePath = filePath.replace("#{buildDir}/", "")
      if relativePath.indexOf('.') == 0
        return false
      if relativePath.indexOf('deploy') == 0
        return false
      return true

    toDir = path.join tmpDir, fileName
    fs.copy buildDir, toDir, { filter }, callback

  setupDirectories: (callback) =>
    console.log '### setting up...'
    { connector, os, arch, tag, buildDir, fileName } = @options
    temp.track()
    fs.removeSync path.join buildDir, "deploy"
    dirName = "#{connector}-#{tag}-#{os}-#{arch}"
    temp.mkdir dirName, (error, tmpDir) =>
      return callback error if error?
      fs.mkdirpSync path.join tmpDir, fileName
      fs.mkdirpSync path.join buildDir, "deploy"
      callback null, tmpDir

  run: (callback) =>
    @setupDirectories (error, tmpDir) =>
      return callback error if error?
      async.series [
        async.apply(@copyToTemp, tmpDir)
        async.apply(@bundler.do, tmpDir)
      ], callback

module.exports = Packager
