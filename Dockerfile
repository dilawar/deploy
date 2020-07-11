# This docker image is based on bhallalab/manylinux2010 which is
# ./hub.docker.com/wheel/Makefile
FROM quay.io/pypa/manylinux2010_x86_64
MAINTAINER Dilawar Singh <dilawar.s.rajput@gmail.com>
RUN yum install -y cmake3 
ARG PYMOOSE_PYPI_PASSWORD
ENV PYMOOSE_PYPI_PASSWORD=$PYMOOSE_PYPI_PASSWORD
WORKDIR /root
COPY ./BRANCH .
COPY ./build_wheels_linux.sh .
RUN PYMOOSE_PYPI_PASSWORD=$PYMOOSE_PYPI_PASSWORD ./build_wheels_linux.sh
