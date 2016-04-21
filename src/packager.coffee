_             = require 'lodash'
fs            = require 'fs-extra'
path          = require 'path'
temp          = require 'temp'
request       = require 'request'
async         = require 'async'
GithubRelease = require './github-release'
Bundler       = require './bundler'

class Packager
  constructor: (@options) ->
    @githubRelease = new GithubRelease @options
    @bundler = new Bundler @options

  downloadStartScript: (tmpDir, callback) =>
    console.log "### getting start script"
    { exeExt, fileName, os, arch } = @options
    destination = path.join(tmpDir, fileName, "start#{exeExt}")
    request({
      baseUrl: "https://github.com/octoblu/go-meshblu-connector-ignition"
      uri: "/releases/download/v1.0.6/meshblu-connector-ignition-#{os}-#{arch}"
    })
    .on 'error', (error) =>
      console.log '### start script error'
      callback error
    .on 'end', =>
      console.log '### start script done'
      fs.chmodSync(destination, '755')
      callback null
    .pipe(fs.createWriteStream(destination))

  copyToTemp: (tmpDir) =>
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
    fs.copySync buildDir, toDir, { filter }

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
      @downloadStartScript tmpDir, (error) =>
        return callback error if error?
        @copyToTemp tmpDir
        @bundler.do tmpDir, (error, bundle) =>
          return callback error if error?
          @githubRelease.upload bundle, callback

module.exports = Packager
