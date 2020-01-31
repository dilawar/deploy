IMAGE := bhallalab/manylinux

all : Dockerfile
	docker build -t $(IMAGE) .

run : 
	docker run -ilt $(IMAGE) bash
