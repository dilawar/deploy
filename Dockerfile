FROM quay.io/pypa/manylinux2010_x86_64
MAINTAINER Dilawar Singh <dilawar.s.rajput@gmail.com>
ARG PYPI_PASSWORD
WORKDIR /root
RUN yum install -y cmake3 git
RUN curl -O https://ftp.gnu.org/gnu/gsl/gsl-2.4.tar.gz \
    && tar xvf gsl-2.4.tar.gz  \
    && cd gsl-2.4  \
    && CFLAGS=-fPIC ./configure --enable-static && make $MAKEOPTS \
    && make install
COPY ./build_wheels_linux.sh .
CMD bash
