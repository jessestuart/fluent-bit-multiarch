#!/bin/sh

source $BASH_ENV

docker tag "$IMAGE:$VERSION-arm64" "$IMAGE:$VERSION-arm"
docker push "$IMAGE:$VERSION-arm"

export PLATFORMS="linux/amd64,linux/arm64,linux/arm"

echo "Downloading manifest-tool."
wget https://github.com/estesp/manifest-tool/releases/download/v0.7.0/manifest-tool-linux-amd64
mv manifest-tool-linux-amd64 /usr/bin/manifest-tool
chmod +x /usr/bin/manifest-tool
manifest-tool --version

# =============================================================================

echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin;
manifest-tool push from-args \
  --platforms "$PLATFORMS" \
  --template "$IMAGE:$VERSION-ARCH" \
  --target "$IMAGE:$VERSION"
if [ "${CIRCLE_BRANCH}" == 'master' ]; then
  manifest-tool push from-args \
    --platforms "$PLATFORMS" \
    --template "$IMAGE:$VERSION-ARCH" \
    --target "$IMAGE:latest"
fi

manifest-tool inspect "$IMAGE:$VERSION"
