#!/bin/sh

echo 'export IMAGE=jessestuart/fluent-bit' >> $BASH_ENV
echo 'export GITHUB_REPO=fluent/fluent-bit' >> $BASH_ENV
curl -s https://api.github.com/repos/fluent/fluent-bit/releases/latest | jq -r ".tag_name" > ./VERSION
echo 'export VERSION=$(cat ./VERSION)' >> $BASH_ENV
echo 'export IMAGE_ID="${REGISTRY}/${IMAGE}:${VERSION}-${TAG}"' >> $BASH_ENV
echo 'export DIR=`pwd`' >> $BASH_ENV
source $BASH_ENV
