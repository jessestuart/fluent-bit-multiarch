#!/bin/sh

# Declare these up here for the sake of clarity; but they won't be persisted
# between `run:` commands without the `$BASH_ENV` dance.
export GITHUB_REPO="fluent/fluent-bit"
export IMAGE="jessestuart/fluent-bit"

curl -s "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" | jq -r ".tag_name" > /VERSION

echo "export IMAGE=${IMAGE}" >> $BASH_ENV
echo "export GITHUB_REPO=${GITHUB_REPO}" >> $BASH_ENV
echo 'export VERSION=$(cat /VERSION)' >> $BASH_ENV
echo 'export IMAGE_ID="${IMAGE}:${VERSION}-${TAG}"' >> $BASH_ENV
echo 'export DIR=`pwd`' >> $BASH_ENV
echo 'export PLATFORMS="linux/amd64,linux/arm64,linux/arm"' >> $BASH_ENV

source $BASH_ENV
