#!/bin/bash

build(){
  npm prune --production \
  && npm install meshblu-connector-packager \
  && npm dedupe \
  && npm install -g flatten-packages \
  && flatten-packages \
  && npm run generate:package \
  && npm run generate:schema \
  && cp schemas.json deploy
}

build_arm(){
  local git_repository="$1"
  local git_ref="$2"
  local connector_name="$(get_connector_name "$git_repository")"

  mkdir -p deploy \
  && docker_run_arm "$git_repository" "$git_ref" \
  && mv deploy/app-linux-arm.tar.gz "deploy/${connector_name}-linux-arm.tar.gz"
}

docker_run_arm(){
  local git_repository="$1"
  local git_ref="$2"
  local current_directory="$(pwd)"

  docker run \
    --rm \
    --volume "$current_directory/deploy":/export \
    octoblu/arm-node-compile:latest \
      ./compile.sh "$git_repository" "$git_ref"
}

fatal(){
  local message="$1"

  echo "$message"
  exit 1
}

get_connector_name(){
  local git_repository="$1"

  echo "$git_repository" \
  | sed -e 's/.*\/meshblu-connector-//'
}

main(){
  local packager_arch="$1"
  local git_repository="$2"
  local git_ref="$3"

  if [ "$packager_arch" == "arm" ]; then
    build_arm "$git_repository" "$git_ref" || fatal "Failed to build arm"
  else
    build || fatal "Failed to build"
  fi

}
main $@
