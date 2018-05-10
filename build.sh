#!/bin/sh -e

ARGS=$*

TAG=$(git rev-parse --short HEAD)
docker build -t gonitro/envoymon:${TAG} $ARGS .
docker push gonitro/envoymon:${TAG}
