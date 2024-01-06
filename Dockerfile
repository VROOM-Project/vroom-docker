FROM debian:bookworm-slim as builder
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

ARG VROOM_RELEASE=master

RUN echo "Cloning and installing vroom release ${VROOM_RELEASE}..." && \
    git clone --branch $VROOM_RELEASE --single-branch --recurse-submodules https://github.com/VROOM-Project/vroom.git && \
    cd vroom && \
    make -C /vroom/src -j$(nproc) && \
    cd /

FROM node:20-bookworm-slim as runstage
COPY --from=builder /vroom-express/. /vroom-express
COPY --from=builder /vroom/bin/vroom /usr/local/bin

WORKDIR /vroom-express

ARG VROOM_EXPRESS_RELEASE=master

RUN apt-get update > /dev/null && \
    apt-get install -y --no-install-recommends \
      libssl3 \
      curl \
      libglpk40 \
      > /dev/null && \
    rm -rf /var/lib/apt/lists/* && \
    # Install vroom-express
    git clone --branch $VROOM_EXPRESS_RELEASE --single-branch https://github.com/VROOM-Project/vroom-express.git && \
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
