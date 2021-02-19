#!/bin/bash
set -ex

APPLICATION=validator
GIT_REV=$(git rev-parse HEAD)
[[ -z $DOCKER_SKIP_CACHE ]] || DOCKER_SKIP_CACHE="--no-cache"

# Build containers
docker build ${DOCKER_SKIP_CACHE} --tag "${APPLICATION}:${GIT_REV}" .
docker tag "${APPLICATION}:${GIT_REV}" "${APPLICATION}:latest"
