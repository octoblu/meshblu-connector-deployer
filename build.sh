#!/bin/bash

print_usage(){
  echo "Usage: ./build.sh <connector-name> <tag>"
}

create_directories(){
  local connector_name="$1"
  local tag="$2"
  mkdir -p "deploy/${connector_name}/latest"
  mkdir -p "deploy/${connector_name}/${tag}"
}

move_connector_to_deploy(){
  local connector_name="$1"
  local tag="$2"
  rsync -avq * "deploy/${connector_name}/latest" --exclude deploy --exclude .git
  rsync -avq * "deploy/${connector_name}/${tag}" --exclude deploy --exclude .git
}

main() {
  if [ "$1" == "--help" -o "$1" == "-h" -o "$1" == "help" -o "$1" == "-?" ]; then
    print_usage
    exit 1
  fi

  if [ -z "$1" ]; then
    print_usage
    echo "Missing connector name"
    exit 1
  fi

  if [ -z "$2" ]; then
    print_usage
    echo "Missing tag"
    exit 1
  fi

  local connector_name="$1"
  local tag="$2"

  create_directories "$connector_name" "$tag"
  move_connector_to_deploy "$connector_name" "$tag"
  exit 0
}

main $@
