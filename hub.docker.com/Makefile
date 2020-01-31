all : moose pymoose

moose : Dockerfile.moose
	docker build -t bhallalab/moose:3.1.4 -f Dockerfile.moose .
	docker build -t bhallalab/moose:latest -f Dockerfile.moose .

pymoose : Dockerfile
	docker build -t bhallalab/pymoose:3.2.git -f Dockerfile .
	docker build -t bhallalab/pymoose:latest -f Dockerfile .


run_pymoose:
	docker run -it bhallalab/pymoose:latest 

upload:
	docker push bhallalab/pymoose:3.2.git
	docker push bhallalab/pymoose:latest
	docker push bhallalab/moose:3.1.4
	docker push bhallalab/moose:latest
