request = require 'request'
fs      = require 'fs-extra'
path    = require 'path'

class Downloader
  constructor: ({ @exeExt, @fileName, @os, @arch, @ignitionVersion }) ->

  downloadStartScript: (tmpDir, callback) =>
    console.log "### downloading start script #{@ignitionVersion}"
    destination = path.join(tmpDir, @fileName, "start#{@exeExt}")
    request({
      baseUrl: "https://github.com/octoblu/go-meshblu-connector-ignition"
      uri: "/releases/download/#{@ignitionVersion}/meshblu-connector-ignition-#{@os}-#{@arch}"
    })
    .on 'error', callback
    .on 'end', =>
      fs.chmod destination, '755', callback
    .pipe(fs.createWriteStream(destination))

module.exports = Downloader
