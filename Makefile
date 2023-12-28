stable:
	docker build -f Dockerfile -t octopus .

develop:
	docker build --progress plain -f Dockerfile-develop -t octopus-develop .

.PHONY: stable develop dockerhub-update-13.0

dockerhub-update-13.0:
	docker build -f Dockerfile -t fangohr/octopus:13.0 .
	@echo "If the container has built successfully, do this to push to dockerhub:"
	@echo "Run 'docker login'"
	@echo "Run 'docker push fangohr/octopus:13.0'"
	@echo "Run 'docker tag fangohr/octopus:13.0 fangohr/octopus:latest'"
	@echo "Run 'docker push fangohr/octopus:latest'"

# multiarch image for DockerHub
dockerhub-update-latest:
	@# https://medium.com/@life-is-short-so-enjoy-it/docker-how-to-build-and-push-multi-arch-docker-images-to-docker-hub-64dea4931df9
	docker buildx create --name container --driver=docker-container
	docker buildx build --tag fangohr/octopus:latest --platform linux/arm64,linux/amd64 --builder container --push .
