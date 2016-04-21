request  = require 'request'
fs       = require 'fs'
path     = require 'path'
_        = require 'lodash'

class GithubRelease
  constructor: ({ @tag, @githubSlug, @githubOauthToken }) ->

  upload: (filePath, callback) =>
    console.log '### publish release files to github...'
    stat = fs.statSync filePath
    fileName = @getFileName filePath
    options =
      baseUrl: "https://uploads.github.com"
      uri: "/repos/#{@githubSlug}/releases/#{@tag}/assets"
      json: true
      headers:
        'Authorization': "token #{@githubOauthToken}"
        'Accept': 'application/vnd.github.manifold-preview'
        'Content-Type': @getContentType(fileName)
        'Content-Length': stat.size
      qs:
        name: fileName

    done = (error, response, body) =>
      return callback error if error?
      return callback new Error("Github release error: #{body.message}") unless response.statusCode == 201
      callback()

    fs.createReadStream(filePath).pipe(request.post(options, done));

  getFileName: (filePath) =>
    return path.basename filePath

  getContentType: (fileName) =>
    ext = _.last(fileName.split('.'))
    return 'application/zip' if ext == "zip"
    return 'application/tar+gzip'

module.exports = GithubRelease
