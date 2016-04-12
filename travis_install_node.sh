#!/bin/bash

install_node(){
  echo "### Installing node"
  if [[ "$PACKAGER_ARCH" == "386" ]]; then
    echo "### using 386 node installation method"
    BASE_URL=$(node -p "v=parseInt(process.versions.node),(v>=1&&v<4?'https://iojs.org/dist/':'https://nodejs.org/dist/')+process.version")
    X86_FILE=$(node -p "v=parseInt(process.versions.node),(v>=1&&v<4?'iojs':'node')+'-'+process.version+'-'+process.platform+'-x86'")
    pushd "/tmp"
      echo "### Download node for x86"
      wget $BASE_URL/$X86_FILE.tar.gz;
      tar -xf $X86_FILE.tar.gz;
      export PATH=$X86_FILE/bin:$PATH;
    popd
  else
    echo "### using amd64 node installation method"
    nvm install $PACKAGER_NODE_VERSION
    nvm use --delete-prefix $PACKAGER_NODE_VERSION
  fi
}

install_nvm(){
  echo "### Install nvm"
  git clone https://github.com/creationix/nvm.git /tmp/.nvm
  source /tmp/.nvm/nvm.sh
}

setup(){
  echo "### Setting up CXX"
  if [[ $TRAVIS_OS_NAME == "linux" ]]; then
    export CXX=g++-4.8;
  fi
  echo "### Verifying CXX"
  $CXX --version
}

verify(){
  echo "### Verifying npm"
  npm --version
  echo "### Verifying node"
  node --version
}

main(){
  setup
  install_nvm
  install_node
  verify
  echo "### Done"
}

main
