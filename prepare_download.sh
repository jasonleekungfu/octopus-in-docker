#!/bin/bash
# This script prepares the download of octopus in the right location given the version number and location to untar / clone
# example run:
# $ ./prepare_download.sh 13.0 /opt/octopus
# $ ./prepare_download.sh develop /opt/octopus

# exit on error
set -e

# Check if the version number and location is provided
if [ -z "$1" ]
  then
    echo "No version number provided"
    exit 1
else
  version=$1
fi
if [ -z "$2" ]
  then
    echo "No location provided"
    exit 1
else
    location=$2
fi

# make the location if it does not exist
if [ ! -d $location ]; then
  mkdir -p $location
fi
cd $location

# if develop is provided, clone the main branch

if [ $version == "develop" ]; then
  git clone https://gitlab.com/octopus-code/octopus.git .
else
    # download the tar file
    wget https://octopus-code.org/download/${version}/octopus-${version}.tar.gz
    tar -xvf octopus-${version}.tar.gz
    mv octopus-$version/* .
    rm -rf octopus-$version
    # rm octopus-$version.tar.gz
fi

date=$(date)

# Record the version number and date
if [ $version == "develop" ]; then
    # Record which version we are using
    git show > octopus-source-version
    echo "octopus-source-clone-date: $date " >> octopus-source-version
else
    # Record which version we are using
    echo "octopus-source-version: $version " > octopus-source-version
    echo "octopus-source-download-date: $date " >> octopus-source-version
fi