_        = require 'lodash'
path     = require 'path'
Packager = require './src/packager'

class CommandBuild
  parseOptions: =>
    buildDir = process.cwd()
    pkg = @getPackageJSON(buildDir)

    options = {
      connector: @getConnectorName(pkg),
      tag: @getVersion(pkg),
      githubSlug: @getGithubSlug(pkg),
      ignitionVersion: @getIgnitionVersion(pkg),
      os: @getOS(),
      arch: @getArch(),
      buildDir: buildDir
    }

    unless options.os in ['darwin', 'windows', 'linux']
      return @panic new Error('Invalid OS, must be one of ["darwin", "windows", "linux"]')

    unless options.arch in ['386', 'amd64']
      return @panic new Error('Invalid ARCH, must be one of ["386", "amd64"]')

    return options

  getPackageJSON: (buildDir) =>
    try
      return require(path.join(buildDir, 'package.json'))
    catch error
      @panic error

  getGithubSlug: (pkg) =>
    { meshbluConnector } = pkg
    { githubSlug } = meshbluConnector
    return githubSlug

  getIgnitionVersion: (pkg) =>
    { meshbluConnector } = pkg
    { ignitionVersion } = meshbluConnector
    return ignitionVersion ? 'v1.0.6'

  getConnectorName: (pkg) =>
    { name } = pkg
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
    arch = process.env.PACKAGER_ARCH || arch
    return '386' if arch == 'ia32'
    return '386' if arch == 'x86'
    return '386' if arch == '386'
    return 'amd64'

  getFileName: (options) =>
    {os, arch} = options
    return "#{os}-#{arch}"

  getFileNameWithExt: (options) =>
    {os, fileName} = options
    ext = "tar.gz"
    ext = "zip" if os == "windows"
    return "#{fileName}.#{ext}"

  getExeExt: (options) =>
    {os} = options
    return ".exe" if os == "windows"
    return ""

  run: =>
    options = @parseOptions()
    options.fileName = @getFileName options
    options.fileNameWithExt = @getFileNameWithExt options
    options.exeExt = @getExeExt options

    console.log "### packaging #{options.connector} #{options.tag} for #{options.os}-#{options.arch}"
    packager = new Packager options
    packager.run (error) =>
      return @panic error if error?
      console.log '### done!'
      process.exit 0

  panic: (error) =>
    console.error error.stack if error?
    process.exit 1

new CommandBuild().run()
