#!/bin/bash

print_usage(){
  echo "Usage: env .. ./build"
  echo "Enviroment:"
  echo "   PACKAGER_CONNECTOR=<connector-name>"
  echo "   PACKAGER_TAG=<tag>"
  echo "   PACKAGER_OS=<os-name>"
  echo "   PACKAGER_ARCH=<os-arch>"
  echo "./build.sh"
}

bundle_connector(){
  echo "### bundling connector..."
  local connector="$1"
  local tag="$2"
  local platform="$3"
  local node_version="$4"
  local filename="${platform}.bundle.tar.gz"
  pushd "deploy/raw" > /dev/null
    tar -zcf "../${connector}/latest/$filename" ./
  popd  > /dev/null
  cp "deploy/${connector}/latest/$filename" "deploy/${connector}/${tag}"
}

clean_start(){
  echo "### cleaning..."
  rm -rf ./deploy
}

clean_end(){
  echo "### cleaning up"
  rm -rf ./deploy/raw
}

create_directories(){
  echo "### creating deploy directories"
  local connector="$1"
  local tag="$2"
  mkdir -p "deploy/raw"
  mkdir -p "deploy/${connector}/latest"
  mkdir -p "deploy/${connector}/${tag}"
}

download_connector_ignition(){
  echo "### download ignition script"
  local platform="$1"
  local tools_uri="https://meshblu-connector.octoblu.com/tools"
  curl -sL "$tools_uri/go-meshblu-connector-ignition/latest/meshblu-connector-ignition-$platform" -o start
  chmod +x start
}

move_connector_to_deploy(){
  echo "### moving to deploy folder"
  local connector="$1"
  local tag="$2"
  rsync -avq * "deploy/raw" --exclude deploy --exclude "./.*"
}

verify_platform() {
  local platform="$1"

  local pattern='^(darwin-386|darwin-amd64|windows-386|windows-amd64|linux-386|linux-amd64)$'
  if ! [[ "$platform" =~ $pattern ]]; then
    echo "Invalid platform type, $platform"
    echo "Must be one of ['darwin-386', 'darwin-amd64', 'windows-386', 'windows-amd64', 'linux-386', 'linux-amd64']"
    exit 1
  fi
}

main() {
  if [ "$1" == "--help" -o "$1" == "-h" -o "$1" == "help" -o "$1" == "-?" ]; then
    print_usage
    exit 1
  fi

  local connector="$PACKAGER_CONNECTOR"
  local tag="$PACKAGER_TAG"
  local os="$PACKAGER_OS"
  local arch="$PACKAGER_ARCH"

  if [ -z "$connector" ]; then
    print_usage
    echo "Missing connector"
    exit 1
  fi

  if [ -z "$tag" ]; then
    print_usage
    echo "Missing tag"
    exit 1
  fi

  if [ -z "$os" ]; then
    print_usage
    echo "Missing operating system"
    exit 1
  fi

  if [ -z "$arch" ]; then
    print_usage
    echo "Missing arch"
    exit 1
  fi

  local platform="${os}-${arch}"

  verify_platform "$platform"

  clean_start
  download_connector_ignition "$platform"
  create_directories "$connector" "$tag"
  move_connector_to_deploy "$connector" "$tag"
  bundle_connector "$connector" "$tag" "$platform"
  clean_end
  echo "### done"
}

main $@
