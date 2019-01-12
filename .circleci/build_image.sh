#!/bin/sh

mkdir build && cd build || return
git clone https://github.com/${GITHUB_REPO} --depth=1 .

# <qemu-support>
if [ "$QEMU_ARCH" = 'amd64' ]; then
  touch qemu-amd64-static
else
  echo "Downloading qemu version ${QEMU_VERSION} for ${QEMU_ARCH}."
  curl -sL "https://github.com/multiarch/qemu-user-static/releases/download/${QEMU_VERSION}/qemu-${QEMU_ARCH}-static.tar.gz" | tar xz
  ls -alh
  docker run --rm --privileged multiarch/qemu-user-static:register
fi
# </qemu-support>

# Replace the repo's Dockerfile with our own.
cp -f "$DIR/Dockerfile" .
touch qemu-

export IMAGE_ID="${IMAGE}:${VERSION}-${TAG}"
docker build -t "$IMAGE_ID" --build-arg target=$TARGET --build-arg lib_target=$LIB_TARGET .
