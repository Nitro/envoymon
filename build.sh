#!/bin/sh

docker build -t envoymon .
id=$(docker create envoymon)
docker cp $id:/build/envoymon .
docker rm -v $id
