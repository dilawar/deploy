# Use the python3.7 image.
FROM python:3.7.6-slim-buster
MAINTAINER Dilawar Singh <dilawar.s.rajput@gmail.com>

RUN apt update
RUN apt install -y python3-scipy python3-networkx graphviz \
  && rm -rf /var/lib/apt/lists/*
RUN python3 -m pip --no-cache-dir install pymoose --pre
RUN python3 -m pip --no-cache-dir install matplotlib numpy 
CMD [ "bash" ]
