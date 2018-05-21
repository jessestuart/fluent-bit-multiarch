#!/bin/sh

mkdir build && cd build || return
git clone https://github.com/${GITHUB_REPO} --depth=1 .

cd lib
rm -rf luajit-2.0.5
curl http://luajit.org/download/LuaJIT-2.1.0-beta3.tar.gz | tar xz

# <qemu-support>
if [ "$QEMU_ARCH" = 'amd64' ]; then
  touch qemu-amd64-static
else
  curl -sL "https://github.com/multiarch/qemu-user-static/releases/download/${QEMU_VERSION}/qemu-${QEMU_ARCH}-static.tar.gz" | tar xz
  docker run --rm --privileged multiarch/qemu-user-static:register
fi
# </qemu-support>

# Replace the repo's Dockerfile with our own.
cp -f $DIR/Dockerfile .

export IMAGE_ID="${IMAGE}:${VERSION}-${TAG}"
docker build -t ${IMAGE_ID} --build-arg target=$TARGET --build-arg arch=$QEMU_ARCH .

# Login to Docker Hub.
# echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin
# # Push push push
# docker push ${IMAGE_ID}
# if [ $CIRCLE_BRANCH == 'master' ]; then
#   docker tag "${IMAGE_ID}" "${REGISTRY}/${IMAGE}:latest-${TAG}"
#   docker push "${REGISTRY}/${IMAGE}:latest-${TAG}"
# fi
