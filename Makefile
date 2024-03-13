# This Makefile is used to build the Docker image for Octopus.
# EXAMPLE: make stable
# EXAMPLE: make develop
# EXAMPLE: make stable VERSION_OCTOPUS=12.0
VERSION_OCTOPUS?=14.0

stable:
	docker build -f Dockerfile --build-arg VERSION_OCTOPUS=${VERSION_OCTOPUS} -t octopus .

develop:
	docker build -f Dockerfile --build-arg VERSION_OCTOPUS=develop -t octopus-develop .

.PHONY: stable develop dockerhub-update-multiarch

# multiarch image for DockerHub. Docker buildkit allows cross-compilation of Docker images.
# Tested by running the following on an M2 machine.
dockerhub-update-multiarch:
	@echo "If the container builds successfully, do this to push to dockerhub:"
	@echo "Run 'docker login'"
	@#if no builder exists yet:
	docker buildx create --name container --driver=docker-container
	@# do the actual multi-platform build, and push to DockerHub
	docker buildx build -f Dockerfile --build-arg VERSION_OCTOPUS=${VERSION_OCTOPUS} \
				--tag fangohr/octopus:${VERSION_OCTOPUS} \
			 	--tag fangohr/octopus:latest \
				--platform linux/arm64,linux/amd64 \
				--builder container \
				--push .


