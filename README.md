# Green-Blue Deployment

This example app uses a Green-Blue Deployment strategy over Docker with [Traefik](https://docs.traefik.io/) as container
discovery system over.

### Prerequisites
* Unbinded ports:
    * 8080 (Dashboard)
    * 8081 (App)

* Docker with socket on `/var/run/docker.sock`, if socket is not there you can modify
 `./deploy/docker-compose.load-balancer.yml` to change the file location.

### How to start

1. Build a first version of your app (The docker-compose files are preconfigured with the v1 tag)
    > ./bin/stackman.sh build v1

2. Start the load balancer
    > ./bin/stackman.sh load-balancer start
    
    You can look the dashboard [here](http://localhost:8080)

3. Start the initial environment
    > ./bin/stackman.sh green start

    You can look the app [here](http://localhost:8081)

4. Try to swap environment
    > ./bin/stackman.sh swap

    You can try building the Dockerfile with a new version to test the B-G Deployment
    
    
### Shutdown
> ./bin/stackman.sh stop
>
> ./bin/stackman.sh load-balancer stop
