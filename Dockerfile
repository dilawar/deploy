FROM quay.io/pypa/manylinux2014_x86_64
MAINTAINER Dilawar Singh <dilawar.s.rajput@gmail.com>

ARG PYPI_PASSWORD

MAINTAINER Dilawar Singh <dilawar.s.rajput@gmail.com>
ENV PATH=/usr/local/bin:$PATH
RUN yum install -y cmake3 wget vim
COPY ./build_wheels_linux.sh /opt/build_wheels_linunx.sh
RUN curl -O https://ftp.gnu.org/gnu/gsl/gsl-2.4.tar.gz
RUN curl -O https://github.com/BhallaLab/deploy/archive/master.tar.gz 
CMD bash
