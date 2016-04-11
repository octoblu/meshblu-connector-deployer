#!/bin/bash

install_node(){
  echo "### Installing node"
  nvm install $PACKAGER_NODE_VERSION
  BASE_URL=$(node -p "v=parseInt(process.versions.node),(v>=1&&v<4?'https://iojs.org/dist/':'https://nodejs.org/dist/')+process.version")
  X86_FILE=$(node -p "v=parseInt(process.versions.node),(v>=1&&v<4?'iojs':'node')+'-'+process.version+'-'+process.platform+'-x86'")
  if [[ "$ARCH" == "386" ]]; then
    echo "### Download node for x86"
    wget $BASE_URL/$X86_FILE.tar.gz;
    tar -xf $X86_FILE.tar.gz;
    export PATH=$X86_FILE/bin:$PATH;
  fi
}

install_nvm(){
  echo "### Install nvm"
  curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.0/install.sh | bash
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
  update_npm
  verify
  echo "### Done"
}

main
