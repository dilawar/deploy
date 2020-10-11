all : wheels

DOCKERFILE:="bhallalab/manylinux-moose:latest"

wheels : ./Dockerfile ./build_wheels_linux.sh 
	mkdir -p $(HOME)/wheelhouse
	docker build -t $(DOCKERFILE) \
	    --build-arg PYPI_PASSWORD=$(PYPI_PASSWORD) . 

run : ./Dockerfile
	docker run -it quay.io/pypa/manylinux2010_x86_64

upload: 
	docker push $(DOCKERFILE)
