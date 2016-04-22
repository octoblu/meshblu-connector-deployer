# meshblu-connector-deployer
[![Build Status](https://travis-ci.org/octoblu/meshblu-connector-packager.svg?branch=master)](https://travis-ci.org/octoblu/meshblu-connector-packager)
[![Code Climate](https://codeclimate.com/github/octoblu/meshblu-connector-packager/badges/gpa.svg)](https://codeclimate.com/github/octoblu/meshblu-connector-packager)
[![Test Coverage](https://codeclimate.com/github/octoblu/meshblu-connector-packager/badges/coverage.svg)](https://codeclimate.com/github/octoblu/meshblu-connector-packager)
[![npm version](https://badge.fury.io/js/.svg)](http://badge.fury.io/js/)
[![Gitter](https://badges.gitter.im/octoblu/help.svg)](https://gitter.im/octoblu/help)


### Manual Usage:

```bash
npm install --global meshblu-connector-packager
cd /path/to/meshblu-connector-{connector-name}
meshblu-connector-packager
```  

### Installation

```bash
cd /path/to/meshblu-connector-{connector-name}
npm install --save-dev meshblu-connector-packager
```

Add the following to your package.json

```json
{
  "scripts": {
    "package": "meshblu-connector-packager"
  },
  "meshbluConnector": {
    "connectorInstallerVersion": "latest",
    "dependencyManagerVersion": "latest",
    "ignitionVersion": "v1.0.6",
    "githubSlug": "octoblu/meshblu-connector-{connector-name}",
    "schemasUrl": "https://raw.githubusercontent.com/octoblu/meshblu-connector-{connector-name}/{schema-tag}/schemas.json"
  }
}
```

### Example Travis Usage

```yml
language: cpp
os:
- linux
- osx
addons:
  apt:
    sources:
    - ubuntu-toolchain-r-test
    packages:
    - g++-4.8
    - g++-4.8-multilib
    - gcc-multilib
    - build-essential
env:
  matrix:
  - PACKAGER_NODE_VERSION="5.5" PACKAGER_ARCH="amd64" MAIN_BUILD="true"
  - PACKAGER_NODE_VERSION="5.5" PACKAGER_ARCH="386"
matrix:
  exclude:
  - os: osx
    env: PACKAGER_NODE_VERSION="5.5" PACKAGER_ARCH="386"
branches:
  only:
  - "/^v[0-9]/"
before_install:
- PACKAGER_URL="https://meshblu-connector.octoblu.com/tools/packager/latest"
- curl -fsS "${PACKAGER_URL}/travis_install_node.sh" -o /tmp/travis_install_node.sh
- chmod +x /tmp/travis_install_node.sh
- ". /tmp/travis_install_node.sh"
- if [ "$TRAVIS_OS_NAME" == "linux" -a "$MAIN_BUILD" == "true" ]; then export NPM_PUBLISH="true"; fi
install:
- npm install --build-from-source
script:
- npm test
before_deploy:
- npm run package
deploy:
- provider: releases
  api_key:
    secure: "secure-api-key"
  file:
  - "deploy/*"
  skip_cleanup: true
  on:
    tags: true
- provider: npm
  email: serveradmin@octoblu.com
  api_key:
    secure: "secure-api-key"
  on:
    tags: true
    condition: "$NPM_PUBLISH = true"
```

*Don't forget to encrypt and add your NPM Key and Github Oauth Token*
