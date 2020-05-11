WEB_SERVICE_SCALE=1

COMMAND=$1
case $COMMAND in
  build)
    VERSION_PARAM=$2

    echo "Building Image Version: ${VERSION_PARAM}\n"

    docker image build -t gb-deployment:${VERSION_PARAM} .
    docker image prune -f
    ;;
  load-balancer)
    COMMAND_PARAM=$2
    echo "Load Balancer: ${COMMAND_PARAM}\n"

    case $COMMAND_PARAM in
      start)
        docker-compose -f deploy/docker-compose.load-balancer.yml -p gb_deployment_load-balancer up -d
        ;;
      stop)
        docker-compose -f deploy/docker-compose.load-balancer.yml -p gb_deployment_load-balancer down
        ;;
    esac
    ;;
  green|blue)
    echo "Environment ${COMMAND}: ${COMMAND_PARAM}\n"

    COMMAND_PARAM=$2
    case $COMMAND_PARAM in
      start)
        docker-compose -f deploy/docker-compose.${COMMAND}.yml -p gb_deployment_${COMMAND} up \
          --scale web=${WEB_SERVICE_SCALE} -d
        ;;
      stop)
        docker-compose -f deploy/docker-compose.${COMMAND}.yml -p gb_deployment_${COMMAND} down
        ;;
    esac
    ;;
  start)
    echo "Starting Blue-Green...\n"

    docker-compose -f deploy/docker-compose.green.yml -p gb_deployment_green up --scale web=${WEB_SERVICE_SCALE} -d
    docker-compose -f deploy/docker-compose.blue.yml  -p gb_deployment_blue  up --scale web=${WEB_SERVICE_SCALE} -d
    ;;
  stop)
    echo "Stopping Blue-Green...\n"
    docker-compose -f deploy/docker-compose.green.yml -p gb_deployment_green down
    docker-compose -f deploy/docker-compose.blue.yml  -p gb_deployment_blue  down
    ;;
  swap)
    echo "Swapping Blue-Green...\n"

    if GREEN_ID=$(docker inspect --format '{{ .Id }}' gb_deployment_green_web_1 2> /dev/null); then
      docker-compose -f deploy/docker-compose.blue.yml  -p gb_deployment_blue  up --scale web=${WEB_SERVICE_SCALE} -d

      BLUE_ID=$(docker inspect --format '{{ .Id }}' gb_deployment_blue_web_1 2> /dev/null);
      BLUE_IP=$(docker network inspect -f "{{ \$container := index .Containers \"${BLUE_ID}\" }}{{ \$container.IPv4Address }}" gb_deployment_load-balancer_my-app)
      BLUE_IP=$(echo $BLUE_IP | cut -d/ -f1)

      RETRIES=5
      while [ $RETRIES -gt 0 ]; do
        RETRIES=$(($RETRIES-1))
        BLUE_STATUS=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' http://${BLUE_IP}:8081/status)

        if [ "$BLUE_STATUS" -eq "200" ]; then
          docker-compose -f deploy/docker-compose.green.yml -p gb_deployment_green down
          exit 0;
        fi

        sleep 2s
      done
    fi

    if BLUE_ID=$(docker inspect --format '{{ .Id }}' gb_deployment_blue_web_1 2> /dev/null); then
      docker-compose -f deploy/docker-compose.green.yml -p gb_deployment_green up --scale web=${WEB_SERVICE_SCALE} -d

      GREEN_ID=$(docker inspect --format '{{ .Id }}' gb_deployment_green_web_1 2> /dev/null);
      GREEN_IP=$(docker network inspect -f "{{ \$container := index .Containers \"${GREEN_ID}\" }}{{ \$container.IPv4Address }}" gb_deployment_load-balancer_my-app)
      GREEN_IP=$(echo $GREEN_IP | cut -d/ -f1)

      RETRIES=5
      while [ $RETRIES -gt 0 ]; do
        RETRIES=$(($RETRIES-1))
        GREEN_STATUS=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' http://${GREEN_IP}:8081/status)

        if [ "$GREEN_STATUS" -eq "200" ]; then
          docker-compose -f deploy/docker-compose.green.yml -p gb_deployment_blue down
          exit 0;
        fi

        sleep 2s
      done
    fi
    ;;
esac
