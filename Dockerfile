FROM quay.io/pypa/manylinux2014_x86_64
MAINTAINER Dilawar Singh <dilawar.s.rajput@gmail.com>

ARG PYPI_PASSWORD

MAINTAINER Dilawar Singh <dilawar.s.rajput@gmail.com>
ENV PATH=/usr/local/bin:$PATH
RUN yum update -y
RUN yum install -y cmake3
RUN yum install -y wget  
RUN wget https://github.com/BhallaLab/deploy/archive/master.tar.gz 
RUN ls -la *.gz
RUN tar xvf master.tar.gz
RUN cd deploy-master && ./build_wheels_linux.sh 
RUN echo "pass $PYPI_PASSWORD"
RUN cd deploy-master && ./test_and_upload.sh "$PYPI_PASSWORD"
