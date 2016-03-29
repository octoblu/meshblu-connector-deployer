#!/bin/bash

print_usage(){
  echo "Usage: ./build.sh <connector-name> <tag> <platform>"
  echo "or"
  echo "Usage: env DEPLOYER_CONNECTOR_NAME=<connector-name> DEPLOYER_TAG=<tag> DEPLOYER_PLATFORM=<platform> ./build.sh"
}

bundle_connector(){
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
  rm -rf "./deploy"
}

clean_end(){
  rm -rf "./deploy/raw"
}

create_directories(){
  local connector_name="$1"
  local tag="$2"
  mkdir -p "deploy/raw"
  mkdir -p "deploy/${connector_name}/latest"
  mkdir -p "deploy/${connector_name}/${tag}"
}

move_connector_to_deploy(){
  local connector_name="$1"
  local tag="$2"
  rsync -avq * "deploy/raw" --exclude deploy --exclude "./.*"
}

main() {
  if [ "$1" == "--help" -o "$1" == "-h" -o "$1" == "help" -o "$1" == "-?" ]; then
    print_usage
    exit 1
  fi

  local connector_name="$1"
  local tag="$2"
  local platform="$3"

  if [ -z "$connector_name" ]; then
    connector_name=$DEPLOYER_CONNECTOR_NAME
  fi

  if [ -z "$tag" ]; then
    tag=$DEPLOYER_TAG
  fi

  if [ -z "$platform" ]; then
    platform=$DEPLOYER_PLATFORM
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

  clean_start
  create_directories "$connector_name" "$tag"
  move_connector_to_deploy "$connector_name" "$tag"
  bundle_connector "$connector_name" "$tag" "$platform"
  clean_end
  exit 0
}

main $@
