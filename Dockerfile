FROM quay.io/pypa/manylinux2010_x86_64
MAINTAINER Dilawar Singh <dilawar.s.rajput@gmail.com>

ARG PYPI_PASSWORD

RUN yum install -y cmake3 git tree && rm -rf /var/cache/yum/*

ENV PATH /usr/local/bin:$PATH 
RUN ln -s /usr/bin/cmake3 /usr/local/bin/cmake

WORKDIR /root

RUN curl -O https://ftp.gnu.org/gnu/gsl/gsl-2.4.tar.gz \
    && tar xvf gsl-2.4.tar.gz  \
    && cd gsl-2.4  \
    && CFLAGS=-fPIC ./configure --enable-static && make $MAKEOPTS \
    && make install

COPY ./build_wheels_linux.sh .
RUN ./build_wheels_linux.sh
CMD [ "bash", "-c", "./build_wheels_linux.sh"]
