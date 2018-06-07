#!/bin/sh

source $BASH_ENV
echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin;

docker pull "$IMAGE:$VERSION-arm64"
docker tag "$IMAGE:$VERSION-arm64" "$IMAGE:$VERSION-arm"
docker push "$IMAGE:$VERSION-arm"

echo "Downloading manifest-tool."
wget https://github.com/estesp/manifest-tool/releases/download/v0.7.0/manifest-tool-linux-amd64
mv manifest-tool-linux-amd64 /usr/bin/manifest-tool
chmod +x /usr/bin/manifest-tool
manifest-tool --version

# =============================================================================

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
