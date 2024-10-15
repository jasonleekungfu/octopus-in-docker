FROM intel/hpckit:2024.1.0-devel-ubuntu22.04

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
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib:/usr/local/cuda/lib64:/usr/lib/x86_64-linux-gnu/

# Install octopus dependencies and compile octopus.
WORKDIR /opt
COPY *.sh /opt
RUN bash /opt/install_dependencies.sh && rm -rf /var/lib/apt/lists/*
RUN bash /opt/install_octopus.sh --version $VERSION_OCTOPUS
RUN rm /opt/*.sh


# ---------------------------------------------------------------------
# Finishing
# ---------------------------------------------------------------------

# offer directory for mounting container
WORKDIR /io

CMD bash -l
