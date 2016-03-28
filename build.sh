#!/bin/bash

print_usage(){
  echo "Usage: ./build.sh <connector-name> <tag>"
  echo "or"
  echo "Usage: env DEPLOYER_CONNECTOR_NAME=<connector-name> DEPLOYER_TAG=<tag> ./build.sh"
}

bundle_connector(){
  local connector_name="$1"
  local tag="$2"
  local filename="bundle.tar.gz"
  pushd "deploy/${connector_name}/latest/raw/" > /dev/null
    tar -zcf "../$filename" ./
  popd  > /dev/null
  cp "deploy/${connector_name}/latest/$filename" "deploy/${connector_name}/${tag}"
}

clean(){
  rm -rf ./deploy
}

create_directories(){
  local connector_name="$1"
  local tag="$2"
  mkdir -p "deploy/${connector_name}/latest/raw"
  mkdir -p "deploy/${connector_name}/${tag}/raw"
}

move_connector_to_deploy(){
  local connector_name="$1"
  local tag="$2"
  rsync -avq * "deploy/${connector_name}/latest/raw" --exclude deploy --exclude ".*" --exclude ".*/"
  rsync -avq * "deploy/${connector_name}/${tag}/raw" --exclude deploy --exclude ".*" --exclude ".*/"
}

main() {
  if [ "$1" == "--help" -o "$1" == "-h" -o "$1" == "help" -o "$1" == "-?" ]; then
    print_usage
    exit 1
  fi

  local connector_name="$1"
  local tag="$2"

  if [ -z "$connector_name" ]; then
    connector_name=$DEPLOYER_CONNECTOR_NAME
  fi

  if [ -z "$tag" ]; then
    tag=$DEPLOYER_TAG
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

  clean
  create_directories "$connector_name" "$tag"
  move_connector_to_deploy "$connector_name" "$tag"
  bundle_connector "$connector_name" "$tag"
  exit 0
}

main $@
