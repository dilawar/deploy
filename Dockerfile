FROM quay.io/pypa/manylinux2010_x86_64

ARG PYPI_PASSWORD

ENV BRANCH chamcham
MAINTAINER Dilawar Singh <dilawar.s.rajput@gmail.com>
ENV PATH=/usr/local/bin:$PATH
RUN yum update -y
RUN yum install -y cmake3
RUN yum install -y wget  
RUN wget https://github.com/dilawar/deploy/archive/$BRANCH.tar.gz 
RUN ls -la *.gz
RUN tar xvf $BRANCH.tar.gz
RUN cd deploy-$BRANCH && ./build_wheels_linux.sh 
RUN echo "pass $PYPI_PASSWORD"
RUN cd deploy-master && ./test_and_upload.sh "$PYPI_PASSWORD"
