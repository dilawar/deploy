all : wheels

DOCKERFILE:="dilawars/pymoose-manylinux2010:latest"

wheels : ./Dockerfile ./build_wheels_linux.sh 
	mkdir -p $(HOME)/wheelhouse
	docker build -t $(DOCKERFILE) \
	    --build-arg PYMOOSE_PYPI_PASSWORD=$(PYMOOSE_PYPI_PASSWORD) . 

run : ./Dockerfile
	docker run -it quay.io/pypa/manylinux2010_x86_64

upload: 
	docker push $(DOCKERFILE)
