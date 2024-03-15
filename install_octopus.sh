#!/bin/bash
# This script prepares the download of octopus in the right location given the version number, location to untar / clone and install prefix
# example run:
# $ ./install_octopus.sh --version 13.0 --download_dir /opt/octopus --install_dir /home/user/octopus-bin
# $ ./install_octopus.sh --version develop --download_dir /opt/octopus
# Consider running install_dependencies.sh first to install all the dependencies on a debian based system



# Function to display script usage
usage() {
  echo "Usage: $0 [--version <version_number>] [--download_dir <download_location>] [--install_dir <install_prefix>]"
  echo "Options:"
  echo "  --version <version_number>      Specify the version number of Octopus (e.g., 13.0, develop)"
  echo "  --download_dir <download_location>   Specify the download location for Octopus source"
  echo "  --install_dir <install_prefix>   Specify the install prefix for Octopus (default: /usr/local)"
  echo "  -h, --help                      Display this help message"
  exit 1
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --version)
      version="$2"
      shift
      shift
      ;;
    --download_dir)
      location="$2"
      shift
      shift
      ;;
    --install_dir)
      prefix="$2"
      shift
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Invalid option: $1"
      usage
      ;;
  esac
done

# Check if the version number and location is provided
if [ -z "$version" ]; then
  echo "No version number provided"
  usage
fi

if [ -z "$location" ]; then
  echo "No download location provided"
  usage
fi

if [ -z "$prefix" ]; then
  echo "No install prefix provided using default location"
  prefix="/usr/local"
fi

## MAIN ##
# exit on error and print each command
set -xe
# make the location if it does not exist
mkdir -p "$location"

cd "$location"

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
  git log -1 --pretty=format:'%H %D' > octopus-source-version
  echo "octopus-source-clone-date: $date " >> octopus-source-version
else
  # Record which version we are using
  echo "octopus-source-version: $version " > octopus-source-version
  echo "octopus-source-download-date: $date " >> octopus-source-version
fi

autoreconf -i

# We need to set FCFLAGS_ELPA as the octopus m4 has a bug
# see https://gitlab.com/octopus-code/octopus/-/issues/900
export FCFLAGS_ELPA="-I/usr/include -I/usr/include/elpa/modules"
mkdir _build && pushd _build
# configure
../configure --enable-mpi --enable-openmp --with-blacs="-lscalapack-openmpi" --prefix="$prefix"

# Which optional dependencies are missing?
cat config.log | grep WARN > octopus-configlog-warnings
cat octopus-configlog-warnings

make -j
make install
make clean
make distclean
