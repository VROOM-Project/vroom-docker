FROM node:12-buster-slim
LABEL maintainer=nils@gis-ops.com

WORKDIR /

RUN echo "Updating apt-get and installing dependencies..." && \
  apt-get -y update > /dev/null && apt-get -y install > /dev/null \
  git-core \
  build-essential \
	g++ \
  libssl-dev \
	libboost-all-dev \
	pkg-config

ARG VROOM_RELEASE=v1.6.0

RUN echo "Cloning and installing vroom release ${VROOM_RELEASE}..." && \
    git clone https://github.com/VROOM-Project/vroom.git && \
    cd vroom && \
    git fetch --tags && \
    git checkout -q $VROOM_RELEASE && \
    make -C /vroom/src && \
    mv /vroom/bin/vroom /usr/local/bin && \
    cd /

ARG VROOM_EXPRESS_RELEASE=v0.5.0

RUN echo "Cloning and installing vroom-express release ${VROOM_EXPRESS_RELEASE}..." && \
    git clone https://github.com/VROOM-Project/vroom-express.git && \
    cd vroom-express && \
    git fetch --tags && \
    git checkout -q $VROOM_EXPRESS_RELEASE && \
    npm config set loglevel error && \
    npm install && \
    # To share the config.yml file with the host
    mkdir /conf

COPY ./docker-entrypoint.sh /docker-entrypoint.sh

ENV VROOM_DOCKER=osrm

EXPOSE 3000
ENTRYPOINT ["/bin/bash"]
CMD ["/docker-entrypoint.sh"]
