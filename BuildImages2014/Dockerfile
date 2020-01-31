FROM quay.io/pypa/manylinux2014_x86_64
MAINTAINER Dilawar Singh <dilawar.s.rajput@gmail.com>

ARG PYPI_PASSWORD

MAINTAINER Dilawar Singh <dilawar.s.rajput@gmail.com>
ENV PATH=/usr/local/bin:$PATH
RUN yum install -y cmake3 wget vim git 
WORKDIR /root
RUN curl -O https://ftp.gnu.org/gnu/gsl/gsl-2.4.tar.gz && \
  tar xvf gsl*.tar.gz && \
  cd gsl* && CFLAGS=-fPIC ./configure --enable-static && make $MAKEOPTS && make install 
COPY build_wheels_linux.sh .
# RUN ./build_wheels_linux.sh
CMD [ "bash" ]
