#!/bin/sh -e

TAG=$(git rev-parse --short HEAD)
docker build -t gonitro/envoymon:${ATG} .
docker push gonitro/envoymon:${TAG}
