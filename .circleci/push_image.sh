#!/bin/sh

# Login to Docker Hub.
echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin
# Push push push
docker push ${IMAGE_ID}
if [ $CIRCLE_BRANCH == 'master' ]; then
  docker tag "${IMAGE_ID}" "${IMAGE}:latest-${TAG}"
  docker push "${IMAGE}:latest-${TAG}"
fi
