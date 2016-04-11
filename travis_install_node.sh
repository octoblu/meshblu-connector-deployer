#!/bin/bash

install_node(){
  echo "### Installing node"
  nvm install --delete-prefix $PACKAGER_NODE_VERSION
  BASE_URL=$(node -p "v=parseInt(process.versions.node),(v>=1&&v<4?'https://iojs.org/dist/':'https://nodejs.org/dist/')+process.version")
  X86_FILE=$(node -p "v=parseInt(process.versions.node),(v>=1&&v<4?'iojs':'node')+'-'+process.version+'-'+process.platform+'-x86'")
  if [[ "$ARCH" == "386" ]]; then
    pushd "/tmp"
      echo "### Download node for x86"
      wget $BASE_URL/$X86_FILE.tar.gz;
      tar -xf $X86_FILE.tar.gz;
      export PATH=$X86_FILE/bin:$PATH;
    popd
  fi
}

install_nvm(){
  echo "### Install nvm"
  git clone https://github.com/creationix/nvm.git ~/.nvm && cd ~/nvm && git checkout `git describe --abbrev=0 --tags`
  source ~/nvm/nvm.sh
}

update_npm(){
  echo "### Updating npm"
  npm install --global npm
}

verify(){
  echo "### Verifying npm"
  npm --version
  echo "### Verifying node"
  node --version
  echo "### Verifying CXX"
  if [[ $TRAVIS_OS_NAME == "linux" ]]; then
    export CXX=g++-4.8;
  fi
  $CXX --version
}

main(){
  install_nvm
  install_node
  verify
  echo "### Done"
}

main
