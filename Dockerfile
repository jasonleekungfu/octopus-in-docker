FROM debian:bookworm

# install Octopus (latest stable or develop) on Debian

# the version to install (latest stable or develop) is set by buildarg VERSION_OCTOPUS
ARG VERSION_OCTOPUS=develop

# Convenience tools (up to emacs)
# Libraries that octopus needs
# and optional dependencies (in alphabetical order)
RUN apt-get -y update && apt-get -y install wget time nano vim emacs \
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
RUN apt-get -y update && apt-get -y install gnuplot \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
COPY prepare_download.sh /opt
RUN bash /opt/prepare_download.sh $VERSION_OCTOPUS /opt/octopus

WORKDIR /opt/octopus
RUN autoreconf -i
# We need to set FCFLAGS_ELPA as the octopus m4 has a bug
# see https://gitlab.com/octopus-code/octopus/-/issues/900
RUN export FCFLAGS_ELPA="-I/usr/include -I/usr/include/elpa/modules" && \
    ./configure --enable-mpi --enable-openmp --with-blacs="-lscalapack-openmpi"

# Which optional dependencies are missing?
RUN cat config.log | grep WARN > octopus-configlog-warnings
RUN cat octopus-configlog-warnings

# all in one line to make image smaller
RUN make -j && make install && make clean && make distclean

# Set ENV variable for external libs (only needed for octopus14.0 onwards)
RUN echo "Section Issue 9 starts here. --------------"
RUN echo "Issue 9: https://github.com/fangohr/octopus-in-docker/issues/9"
# DEBUG output
RUN ldd /usr/local/bin/octopus | grep libsym
RUN echo $LD_LIBRARY_PATH
# Setting LD_LIBRARY_PATH as follows works around the octopus bug described in
# https://github.com/fangohr/octopus-in-docker/issues/9 and also referenced in
# https://gitlab.com/octopus-code/octopus/-/issues/886
ENV LD_LIBRARY_PATH=/usr/local/lib
RUN echo $LD_LIBRARY_PATH
RUN echo "Section Issue 9 ends here. ----------------"
# Section specifically for develop branch.
RUN echo "Section Issue 9 starts here. --------------"
RUN echo "Issue 9: https://github.com/fangohr/octopus-in-docker/issues/9"
# DEBUG output
RUN if [ "${VERSION_OCTOPUS}" = "develop" ]; then ldd /usr/local/bin/octopus | grep libsym; fi
RUN echo $LD_LIBRARY_PATH
# Setting LD_LIBRARY_PATH as follows works around the octopus bug described in
# https://github.com/fangohr/octopus-in-docker/issues/9 and also referenced in
# https://gitlab.com/octopus-code/octopus/-/issues/886
ENV LD_LIBRARY_PATH=/usr/local/lib
RUN echo $LD_LIBRARY_PATH
RUN echo "Section Issue 9 ends here. ----------------"

RUN octopus --version > octopus-version
RUN octopus --version

# The next command returns an error code as some tests fail
# RUN make check-short

RUN mkdir -p /opt/octopus-examples
COPY examples /opt/octopus-examples

# Instead of tests, run two short examples
RUN cd /opt/octopus-examples/recipe && octopus
RUN cd /opt/octopus-examples/h-atom && octopus
RUN cd /opt/octopus-examples/he && octopus

# allow root execution of mpirun
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# set number of OpenMP threads to 1 by default
ENV OMP_NUM_THREADS=1

# run one MPI-enabled version
RUN cd /opt/octopus-examples/he && mpirun -np 1 octopus
RUN cd /opt/octopus-examples/he && mpirun -np 2 octopus

# test the libraries used by octopus
RUN cd /opt/octopus-examples/recipe && octopus > /tmp/octopus-recipe.out
# test that the libraries are mentioned in the configuration options section of octopus output
RUN grep "Configuration options" /tmp/octopus-recipe.out | grep "openmp"
RUN grep "Configuration options" /tmp/octopus-recipe.out | grep "mpi"
# test that the libraries are mentioned in the optional libraries section of octopus output
RUN grep "Optional libraries" /tmp/octopus-recipe.out | grep "cgal"
RUN grep "Optional libraries" /tmp/octopus-recipe.out | grep "scalapack"
RUN grep "Optional libraries" /tmp/octopus-recipe.out | grep "ELPA"

# offer directory for mounting container
WORKDIR /io

CMD bash -l
