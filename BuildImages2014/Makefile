IMAGE := bhallalab/manylinux

all : Dockerfile
	docker build -t $(IMAGE) .

run : 
	docker run -it $(IMAGE) bash
