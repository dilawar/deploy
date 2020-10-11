all : wheels

DOCKERFILE:="bhallalab/manylinux-moose:latest"

wheels : ./Dockerfile ./build_wheels_linux.sh 
	mkdir -p $(HOME)/wheelhouse
	docker build -t $(DOCKERFILE) \
	    --build-arg PYPI_PASSWORD=$(PYPI_PASSWORD) . 

run : ./Dockerfile
	docker run -it $(DOCKERFILE) bash

upload: 
	docker push $(DOCKERFILE)
