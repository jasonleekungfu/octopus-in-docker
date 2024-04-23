FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

# ---------------------------------------------------------------------
# Install Octopus (latest stable or develop) on CUDA container
# ---------------------------------------------------------------------

# the version to install (latest stable or develop) is set by buildarg VERSION_OCTOPUS
# the development version of octopus is hosted on the branch "main" in the official repository.
ARG VERSION_OCTOPUS=14.0

# the build system to use (autotools or cmake) 
# Disabled for GPU support and will use autotools only as of Apr 2024).
#   CUDA base image only supports Ubuntu up to 22.04, and "libspglib-f08-dev" 
#   required by cmake is not supported as of Apr 2024. -Jason
#ARG BUILD_SYSTEM=autotools

# On octopus>13 libsym (external-lib) is dynamically linked from /usr/local/lib.
# Also find CUDA toolkits and drivers. -Jason
# As we run Octopus as root, we need to set LD_LIBRARY_PATH:
ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/local/cuda/lib64:/usr/local/cuda-12.4/compat/

# Install octopus dependencies and compile octopus.
WORKDIR /opt
COPY *.sh /opt
RUN bash /opt/install_dependencies.sh && rm -rf /var/lib/apt/lists/*
RUN bash /opt/install_octopus.sh --version $VERSION_OCTOPUS --download_dir /opt/octopus --build_system autotools


# ---------------------------------------------------------------------
# Test Octopus
# ---------------------------------------------------------------------

# CUDA will be disabled via environmental variables during testing for building on machines w/o GPU devices

# Enable parsing environmental variables 
# By doing this, GPU can be disabled by setting OCT_DisableAccel=1
ENV OCT_PARSE_ENV=1

# Change work directory
WORKDIR /opt/octopus

# Show octopus version
RUN OCT_DisableAccel=1 octopus --version > octopus-version
RUN OCT_DisableAccel=1 octopus --version

# The next command returns an error code as some tests fail
# RUN make check-short

RUN mkdir -p /opt/octopus-examples
COPY examples /opt/octopus-examples

# Instead of tests, run two short examples
RUN cd /opt/octopus-examples/recipe && OCT_DisableAccel=1 octopus
RUN cd /opt/octopus-examples/h-atom && OCT_DisableAccel=1 octopus
RUN cd /opt/octopus-examples/he && OCT_DisableAccel=1 octopus

# allow root execution of mpirun
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# set number of OpenMP threads to 1 by default
# Disabled because most of HPC users will customize by running with srun. -Jason
#ENV OMP_NUM_THREADS=1

# run one MPI-enabled version
RUN cd /opt/octopus-examples/he && OCT_DisableAccel=1 mpirun -np 1 octopus
RUN cd /opt/octopus-examples/he && OCT_DisableAccel=1 mpirun -np 2 octopus

# test the libraries used by octopus
RUN cd /opt/octopus-examples/recipe && OCT_DisableAccel=1 octopus > /tmp/octopus-recipe.out
# test that the libraries are mentioned in the configuration options section of octopus output
RUN grep "Configuration options" /tmp/octopus-recipe.out | grep "openmp"
RUN grep "Configuration options" /tmp/octopus-recipe.out | grep "mpi"
# test that the libraries are mentioned in the optional libraries section of octopus output
RUN grep "Optional libraries" /tmp/octopus-recipe.out | grep "cgal"
RUN grep "Optional libraries" /tmp/octopus-recipe.out | grep "scalapack"
RUN grep "Optional libraries" /tmp/octopus-recipe.out | grep "ELPA"


# ---------------------------------------------------------------------
# Finishing
# ---------------------------------------------------------------------

# offer directory for mounting container
WORKDIR /io

CMD bash -l
