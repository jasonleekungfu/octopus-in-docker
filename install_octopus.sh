#!/bin/bash
# This script prepares the download of octopus in the right location given the version number, location to untar / clone and install prefix
# example run:
# $ ./install_octopus.sh 13.0 /opt/octopus /home/user/octopus-bin
# $ ./install_octopus.sh develop /opt/octopus

# exit on error and print each command
set -xe

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
    echo "No download location provided"
    exit 1
else
    location=$2
fi
if [ -z "$3" ]
  then
    echo "No install prefix provided using default location"
    prefix=/usr/local
else
    prefix=$3
fi

# Convenience tools (up to emacs)
# Libraries that octopus needs
# and optional dependencies (in alphabetical order)
apt-get -y update && apt-get -y install wget time nano vim emacs \
    autoconf \
    automake \
    build-essential \
    g++ \
    gcc \
    gfortran \
    git \
    libatlas-base-dev \
    libblas-dev \
    libboost-dev \
    libcgal-dev \
    libelpa-dev \
    libetsf-io-dev \
    libfftw3-dev \
    libgmp-dev \
    libgsl-dev \
    liblapack-dev \
    liblapack-dev \
    libmpfr-dev \
    libnetcdff-dev \
    libnlopt-dev \
    libopenmpi-dev \
    libscalapack-mpi-dev \
    libspfft-dev \
    libtool \
    libxc-dev \
    libyaml-dev \
    openscad \
    openctm-tools \
    pkg-config \
    procps \
    && rm -rf /var/lib/apt/lists/*


# Add optional packages not needed by octopus (for visualization)
apt-get -y update && apt-get -y install gnuplot \
  && rm -rf /var/lib/apt/lists/*



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

autoreconf -i

# We need to set FCFLAGS_ELPA as the octopus m4 has a bug
# see https://gitlab.com/octopus-code/octopus/-/issues/900
export FCFLAGS_ELPA="-I/usr/include -I/usr/include/elpa/modules"
mkdir _build && pushd _build
# configure
../configure --enable-mpi --enable-openmp --with-blacs="-lscalapack-openmpi" --prefix=$prefix

# Which optional dependencies are missing?
cat config.log | grep WARN > octopus-configlog-warnings
cat octopus-configlog-warnings

# all in one line to make image smaller
make -j && make install && make clean && make distclean



if [ $version == "develop" ]; then
  # Set ENV variable for external libs (only needed for octopus14.0 onwards)
  echo "Section Issue 9 starts here. --------------"
  echo "Issue 9: https://github.com/fangohr/octopus-in-docker/issues/9"
  # DEBUG output
  ldd /usr/local/bin/octopus | grep libsym
  echo $LD_LIBRARY_PATH
  # Setting LD_LIBRARY_PATH as follows works around the octopus bug described in
  # https://github.com/fangohr/octopus-in-docker/issues/9 and also referenced in
  # https://gitlab.com/octopus-code/octopus/-/issues/886
  ENV LD_LIBRARY_PATH=/usr/local/lib
  echo $LD_LIBRARY_PATH
  echo "Section Issue 9 ends here. ----------------"
  # Section specifically for develop branch.
  echo "Section Issue 9 starts here. --------------"
  echo "Issue 9: https://github.com/fangohr/octopus-in-docker/issues/9"
  # DEBUG output
  if [ "${VERSION_OCTOPUS}" = "develop" ]; then ldd /usr/local/bin/octopus | grep libsym; fi
  echo $LD_LIBRARY_PATH
  # Setting LD_LIBRARY_PATH as follows works around the octopus bug described in
  # https://github.com/fangohr/octopus-in-docker/issues/9 and also referenced in
  # https://gitlab.com/octopus-code/octopus/-/issues/886
  ENV LD_LIBRARY_PATH=/usr/local/lib
  echo $LD_LIBRARY_PATH
  echo "Section Issue 9 ends here. ----------------"

fi

