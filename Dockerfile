FROM debian:buster-slim as builder
LABEL maintainer=nils@gis-ops.com

WORKDIR /

RUN echo "Updating apt-get and installing dependencies..." && \
  apt-get -y update > /dev/null && apt-get -y install > /dev/null \
  git-core \
  build-essential \
	g++ \
  libssl-dev \
	libasio-dev \
  libglpk-dev \
	pkg-config

ARG VROOM_RELEASE=v1.9.0

RUN echo "Cloning and installing vroom release ${VROOM_RELEASE}..." && \
    git clone https://github.com/VROOM-Project/vroom.git && \
    cd vroom && \
    git fetch --tags && \
    git checkout -q $VROOM_RELEASE && \
    make -C /vroom/src && \
    cd /

# TODO: change to release version again
ARG VROOM_EXPRESS_RELEASE=v0.8.0

RUN echo "Cloning and installing vroom-express release ${VROOM_EXPRESS_RELEASE}..." && \
    git clone https://github.com/VROOM-Project/vroom-express.git && \
    cd vroom-express && \
    git fetch --tags && \
    git checkout $VROOM_EXPRESS_RELEASE

FROM node:12-buster-slim as runstage
COPY --from=builder /vroom-express/. /vroom-express
COPY --from=builder /vroom/bin/vroom /usr/local/bin

WORKDIR /vroom-express

RUN apt-get update > /dev/null && \
    apt-get install -y --no-install-recommends \
      libssl1.1 \
      curl \
      libglpk40 \
      > /dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    # Install vroom-express
    npm config set loglevel error && \
    npm install && \
    # To share the config.yml & access.log file with the host
    mkdir /conf


COPY ./docker-entrypoint.sh /docker-entrypoint.sh
ENV VROOM_DOCKER=osrm \
    VROOM_LOG=/conf

HEALTHCHECK --start-period=10s CMD curl --fail -s http://localhost:3000/health || exit 1

EXPOSE 3000
ENTRYPOINT ["/bin/bash"]
CMD ["/docker-entrypoint.sh"]
