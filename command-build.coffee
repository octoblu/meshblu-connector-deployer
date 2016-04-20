_       = require 'lodash'
fs      = require 'fs-extra'
path    = require 'path'
temp    = require 'temp'
request = require 'request'
TarGz   = require 'tar.gz'
zipdir  = require 'zip-dir'

class CommandBuild
  parseOptions: =>
    build_dir = process.cwd()
    args = {
      connector: process.env.PACKAGER_CONNECTOR
      tag: process.env.PACKAGER_TAG
      os: process.env.PACKAGER_OS
      arch: process.env.PACKAGER_ARCH
    }

    pkg = @getPackageJSON(build_dir)

    defaults = {
      connector: @getConnectorName(pkg),
      tag: @getVersion(pkg),
      os: @getOS(),
      arch: @getArch(),
      build_dir: build_dir
    }

    options = _.defaults(defaults, args)

    return @panic new Error('Missing PACKAGER_CONNECTOR') unless options.connector?
    return @panic new Error('Missing PACKAGER_TAG') unless options.tag?
    return @panic new Error('Missing PACKAGER_OS') unless options.os?
    return @panic new Error('Missing PACKAGER_ARCH') unless options.arch?

    unless options.os in ['darwin', 'windows', 'linux']
      return @panic new Error('Invalid OS, must be one of ["darwin", "windows", "linux"]')

    unless options.arch in ['386', 'amd64']
      return @panic new Error('Invalid ARCH, must be one of ["386", "amd64"]')

    console.log("### packaging #{options.connector} #{options.tag} for #{options.os}-#{options.arch}")

    @options = options

  getPackageJSON: (build_dir) =>
    return require(path.join(build_dir, 'package.json'))

  getConnectorName: (pkg) =>
    {name} = pkg
    return name.replace('meshblu-connector-', '') if name.indexOf('meshblu-connector-') > -1
    return name.replace('meshblu-', '') if name.indexOf('meshblu-') > -1
    return name

  getVersion: (pkg) =>
    return "v#{pkg.version}"

  getOS: =>
    {platform} = process
    return 'windows' if platform == 'win32'
    return platform

  getArch: =>
    {arch} = process
    return '386' if arch == 'ia32'
    return '386' if arch == 'x86'
    return '386' if arch == '386'
    return 'amd64'

  getFileName: =>
    {os, arch} = @options
    return "#{os}-#{arch}.bundle"

  getFileNameWithExt: =>
    {os} = @options
    ext = "tar.gz"
    ext = "zip" if os == "windows"
    return "#{@getFileName()}.#{ext}"

  getStartScript: (tmpDir, callback) =>
    console.log "### getting start script"
    {os, arch} = @options
    ext = ""
    ext = ".exe" if os == "windows"
    destination = path.join(tmpDir, @getFileName(), "start#{ext}")
    request({
      baseUrl: "https://meshblu-connector.octoblu.com/tools"
      uri: "/go-meshblu-connector-ignition/v1.0.1/meshblu-connector-ignition-#{os}-#{arch}"
    })
    .on 'error', (error) =>
      console.log '### start script error'
      callback error
    .on 'end', =>
      console.log '### start script done'
      fs.chmodSync(destination, '755')
      callback null
    .pipe(fs.createWriteStream(destination))

  bundle: (tmpDir, tag) =>
    console.log "### bundling #{tag}"
    {build_dir, connector, os} = @options
    destination = path.join(build_dir, "deploy/#{connector}/#{tag}", @getFileNameWithExt())
    bundle_dir = path.join tmpDir, @getFileName()
    @tarGz bundle_dir, destination if os != "windows"
    @zip bundle_dir, destination if os == "windows"

  tarGz: (bundle_dir, destination) =>
    new TarGz({}, {fromBase: true}).compress bundle_dir, destination, (error) =>
      return @panic error if error?

  zip: (bundle_dir, destination) =>
    zipdir bundle_dir, {saveTo: destination}, (error) =>
      return @panic error if error?

  copyToTemp: (tmpDir) =>
    console.log '### copying to temp'
    {build_dir} = @options
    filter = (filePath) =>
      relativePath = filePath.replace("#{build_dir}/", "")
      if relativePath.indexOf('.') == 0
        return false
      if relativePath.indexOf('deploy') == 0
        return false
      return true

    toDir = path.join tmpDir, @getFileName()
    fs.copySync build_dir, toDir, {filter}

  setupDirectories: (callback) =>
    console.log '### setting up...'
    {connector, os, arch, tag, build_dir} = @options
    fs.removeSync path.join(build_dir, "deploy")
    dirName = "#{connector}-#{tag}-#{os}-#{arch}"
    temp.mkdir dirName, (error, tmpDir) =>
      return callback error if error?
      fs.mkdirpSync path.join(tmpDir, @getFileName())
      callback null, tmpDir

  run: =>
    @parseOptions()
    temp.track()
    @setupDirectories (error, tmpDir) =>
      return @panic error if error?
      @getStartScript tmpDir, (error) =>
        return @panic error if error?
        @copyToTemp tmpDir
        {connector, tag, build_dir} = @options
        fs.mkdirpSync path.join build_dir, "deploy/#{connector}/latest"
        fs.mkdirpSync path.join build_dir, "deploy/#{connector}/#{tag}"
        @bundle tmpDir, 'latest'
        @bundle tmpDir, @options.tag

  panic: (error) =>
    console.error error.stack if error?
    process.exit 1

new CommandBuild().run()
