#!/bin/bash

# Check if build folder, username, and access token are provided as arguments
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "Usage: $0 <build_folder> <docker_username> <docker_access_token>"
  exit 1
fi

# Get the arguments
build_folder="$1"
docker_username="$2"
docker_access_token="$3"

# Check if the build folder exists
if [ ! -d "$build_folder" ]; then
  echo "Error: Build folder '$build_folder' does not exist."
  exit 1
fi

cd $build_folder

if ! docker login -u "$docker_username" -p "$docker_access_token"; then
  echo "Error: Docker login failed."
  exit 1
fi

date_tag=$(date +%Y_%m_%d)

if ! docker build -t "$docker_username/qbittorrent:latest" "$build_folder"; then
  echo "Error: Docker build failed."
  exit 1
fi

if ! docker tag "$docker_username/qbittorrent:latest" "$docker_username/qbittorrent:$date_tag"; then
  echo "Error: Docker tag failed."
  exit 1
fi

if ! docker push --all-tags "$docker_username/qbittorrent"; then
  echo "Error: Docker push failed."
  exit 1
fi

echo "Docker image built and pushed to Docker Hub."


