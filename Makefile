stable:
	docker build -f Dockerfile -t octopus .

develop:
	docker build --progress plain -f Dockerfile-develop -t octopus-develop .

.PHONY: stable develop dockerhub-update-multiarch

# multiarch image for DockerHub
dockerhub-update-multiarch:
	@echo "If the container builds successfully, do this to push to dockerhub:"
	@echo "Run 'docker login'"
	@#if no builder exists yet:
	docker buildx create --name container --driver=docker-container
	docker buildx build --tag fangohr/octopus:13.0 --tag fangohr/octopus:latest --platform linux/arm64,linux/amd64 --builder container --push .


