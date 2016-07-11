#!/bin/bash

fatal(){
  local message="$1"

  echo "$message"
  exit 1
}

install_node(){
  local node_version="$1"
  local os_arch="$2"
  echo "* installing node $node_version"
  nvm install "$node_version"
  local base_url="$(node -p "v=parseInt(process.versions.node),(v>=1&&v<4?'https://iojs.org/dist/':'https://nodejs.org/dist/')+process.version")"
  local x86_file=$(node -p "v=parseInt(process.versions.node),(v>=1&&v<4?'iojs':'node')+'-'+process.version+'-'+process.platform+'-x86'")
  if [[ "$os_arch" == "386" ]]; then
    pushd "/tmp" > /dev/null
      echo '* download node for x86'
      wget "$base_url/$x86_file.tar.gz";
      tar -xf $x86_file.tar.gz;
      export PATH=$x86_file/bin:$PATH;
    popd > /dev/null
  fi
}

install_nvm(){
  echo '* install nvm'
  rm -rf ~/.nvm
  git clone https://github.com/creationix/nvm.git ~/.nvm || return 1
  pushd ~/.nvm > /dev/null
    git checkout `git describe --abbrev=0 --tags` || return 1
  popd > /dev/null
  source ~/.nvm/nvm.sh
}

setup(){
  local os_name="$1"
  echo '* setting up CXX'
  if [[ "$os_name" == "linux" ]]; then
    export CXX=g++-4.8;
  fi
}

verify(){
  echo '* verifying npm'
  npm --version || return 1
  echo '* verifying node'
  node --version || return 1
  echo '* verifying CXX'
  $CXX --version || return 1
}

main(){
  echo '* installing node'
  local node_version="$PACKAGER_NODE_VERSION"
  if [ -z "$node_version" ]; then
    echo 'Missing PACKAGER_NODE_VERSION environment'
    exit 1
  fi
  local os_name="$TRAVIS_OS_NAME"
  if [ -z "$os_name" ]; then
    echo 'Missing TRAVIS_OS_NAME environment'
    exit 1
  fi
  local os_arch="$PACKAGER_ARCH"
  if [ -z "$os_arch" ]; then
    echo 'Missing PACKAGER_ARCH environment'
    exit 1
  fi

  setup "$os_name"                        || fatal "Failed to setup"
  install_nvm                             || fatal "Failed to install nvm"
  install_node "$node_version" "$os_arch" || fatal "Failed to install node"
  verify                                  || fatal "Failed to verify"

  echo '* done'
}

main
