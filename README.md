# VROOM Docker image

This image includes all dependencies and projects needed to successfully run an instance of [`vroom-express`](https://github.com/VROOM-Project/vroom-express) on top of [`vroom`](https://github.com/VROOM-Project/vroom). Within 2 minutes you'll have a routing optimization engine running on your machine.

```bash
docker run -dt --name vroom \
    --net host \  # or set the container name as host in config.yml and use --port 3000:3000 instead, see below
    -v $PWD/conf:/conf \ # mapped volume for config & log
    -e VROOM_ROUTER=ors \ # routing layer: osrm or ors
    vroomvrp/vroom-docker:v1.6.0
```

If you want to build the image yourself, run a

`docker build -t vroomproject/vroom-docker:v1.6.0 --build-arg VROOM_RELEASE=v1.6.0 --build-arg VROOM_EXPRESS_RELEASE=v0.5.0 .`

> **Note**, you should have access to a self-hosted instance of OSRM or OpenRouteService for the routing server, see e.g. [`docker-compose.yml`](docker-compose.yml) for an example.

## Tagging

The tagging scheme follows the release convention of `vroom` and adds patch releases for `vroom-express` patch releases.

## Customization

### Environment variables

- `VROOM_ROUTER`: specifies the routing engine to be used, `osrm` or `ors`. Default `osrm`.

The pre-configured host for the routing servers is `localhost` and `port: 8080` for ORS, `port: 5000` for OSRM.

### Volume mounting

All relevant files are located inside the container's `/conf` directory and can be shared with the host. These include:

- `access.log`: the server log for `vroom-express`
- `config.yml`: the server configuration file, which gives you full control over the `vroom-express` configuration. If you need to edit the configuration, run `docker restart vroom` to restart the server with the new settings.

Add a `-v $PWD/conf:/conf` to your `docker run` command.

> **Note**, the environment variable `VROOM_ROUTER` has precedence over the `router` setting in `config.yml`.

### Build arguments

If you prefer to build the image from source, there are 2 build arguments:

- `VROOM_RELEASE`: specifies VROOM's git [branch](https://github.com/VROOM-Project/vroom/branches), [commit hash](https://github.com/VROOM-Project/vroom/commits/master) or [release](https://github.com/VROOM-Project/vroom/releases) (e.g. `v1.6.0`) to install in the container
- `VROOM_EXPRESS_RELEASE`: specifies `vroom-express`'s git [branch](https://github.com/VROOM-Project/vroom-express/branches), [commit hash](https://github.com/VROOM-Project/vroom-express/commits/master) or [release](https://github.com/VROOM-Project/vroom-express/releases) (e.g. `v0.6.0`) to install in the container

> **Note**, not all versions are compatible with each other

## docker-compose

We include a [`docker-compose.yml`](docker-compose.yml) in the project to get you started easily.

`docker-compose up -d` will pull the latest `vroom-docker` image and the latest `openrouteservice` docker image.

## Routing Server

You have the option to use [OpenRouteService](github.com/GIScience/openrouteservice) or [OSRM](https://github.com/Project-OSRM/osrm-backend). However, the proper setup in Docker or `docker-compose` depends on how you run the routing server.

### Routing server in local Docker container

If you started the routing layer in a separate Docker container via `docker run`, you'll have to start the `vroom` container on the `host` network by adding `--net host`. The disadvantage is that you'll have to assign `vroom-express` configured `port` on the host machine. If port 3000 is already occupied on your machine, configure a different port in `config.yml`.

Alternatively you can add both containers to a private Docker network and change the routing server host(s) to the routing server container name(s) in `config.yml` before restarting the `vroom` container. However, the concepts involved are beyond the scope of this project.

### Whole stack started with `docker-compose`

Make sure to include a `network_mode: host` in your `vroom` service section, which will have the same effect as adding `--net host` to a `docker run` statement.

Also here the alternative is to create a private Docker network, where your services only publish the ports needed to run the stack. Note, you'll have to change the host(s) in `config.yml` to the service name(s) defined in `docker-compose.yml`.

### Routing server on a remote server

In this case, you'll have to edit the mapped `config.yml` to include the host and port you published the routing server on.
