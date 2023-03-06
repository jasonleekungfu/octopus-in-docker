stable:
	docker build -f Dockerfile -t octopus .

develop:
	docker build -f Dockerfile-develop -t octopus-develop .

.PHONY: stable develop dockerhub-update-12.2

dockerhub-update-12.2:
	docker build -f Dockerfile -t fangohr/octopus:12.2 .
	@echo "If the container has built successfully, do this to push to dockerhub:"
	@echo "Run 'docker login'"
	@echo "Run 'docker push fangohr/octopus:12.2'"
	@echo "Run 'docker tag fangohr/octopus:12.2 fangohr/octopus:latest'"
	@echo "Run 'docker push fangohr/octopus:latest'"
