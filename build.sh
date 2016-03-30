#!/bin/bash

print_usage(){
  echo "Usage: ./build.sh <connector-name> <tag> <platform>"
  echo "or"
  echo "Usage: env PACKAGER_CONNECTOR_NAME=<connector-name> PACKAGER_TAG=<tag> PACKAGER_PLATFORM=<platform> ./build.sh"
}

bundle_connector(){
  echo "### bundling connector..."
  local connector_name="$1"
  local tag="$2"
  local platform="$3"
  local filename="${platform}.bundle.tar.gz"
  pushd "deploy/raw" > /dev/null
    tar -zcf "../${connector_name}/latest/$filename" ./
  popd  > /dev/null
  cp "deploy/${connector_name}/latest/$filename" "deploy/${connector_name}/${tag}"
}

clean_start(){
  echo "### cleaning..."
  rm -rf "./deploy"
}

clean_end(){
  echo "### cleaning up"
  rm -rf "./deploy/raw"
}

convert_travis_os_to_platform(){
  local platform="$1"
  if [ "$platform" == "osx" ]; then
    echo "darwin"
    exit 0
  fi
  echo "$platform"
}

create_directories(){
  echo "### creating deploy directories"
  local connector_name="$1"
  local tag="$2"
  mkdir -p "deploy/raw"
  mkdir -p "deploy/${connector_name}/latest"
  mkdir -p "deploy/${connector_name}/${tag}"
}

move_connector_to_deploy(){
  echo "### moving to deploy folder"
  local connector_name="$1"
  local tag="$2"
  rsync -avq * "deploy/raw" --exclude deploy --exclude "./.*"
}

verify_project(){
  echo "### verifying project"
  if [ ! -f "./start" ]; then
    echo "Missing start script"
    exit 1
  fi
  if [ ! -x "./start" ]; then
    echo "Start script is not executable"
    exit 1
  fi
}

main() {
  if [ "$1" == "--help" -o "$1" == "-h" -o "$1" == "help" -o "$1" == "-?" ]; then
    print_usage
    exit 1
  fi

  verify_project

  local connector_name="$1"
  local tag="$2"
  local platform="$3"

  if [ -z "$connector_name" ]; then
    connector_name=$PACKAGER_CONNECTOR_NAME
  fi

  if [ -z "$tag" ]; then
    tag=$PACKAGER_TAG
  fi

  if [ -z "$platform" ]; then
    platform=$PACKAGER_PLATFORM
  fi

  if [ -z "$connector_name" ]; then
    print_usage
    echo "Missing connector name"
    exit 1
  fi

  if [ -z "$tag" ]; then
    print_usage
    echo "Missing tag"
    exit 1
  fi

  if [ -z "$platform" ]; then
    print_usage
    echo "Missing platform"
    exit 1
  fi

  platform=$(convert_travis_os_to_platform "$platform")

  clean_start
  create_directories "$connector_name" "$tag"
  move_connector_to_deploy "$connector_name" "$tag"
  bundle_connector "$connector_name" "$tag" "$platform"
  clean_end
  exit 0
}

main $@
