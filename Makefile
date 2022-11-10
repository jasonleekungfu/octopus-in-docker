stable:
	docker build -f Dockerfile-debian -t octopus .

develop:
	docker build -f Dockerfile-debian-develop -t octopus-develop .

.PHONY: stable debian-octopusdevelop 

dockerhub-update-12.1:
	docker build -f Dockerfile-debian -t fangohr/octopus:12.1 .
	@echo "If the container has built successfully, do this to push to dockerhub:"
	@echo "Run 'docker login'"
	@echo "Run 'docker push fangohr/octopus:12.1'"
	@echo "Run 'docker tag fangohr/octopus:12.1 fangohr/octopus:latest'"
	@echo "Run 'docker push fangohr/octopus:latest'"
