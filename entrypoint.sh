#!/bin/bash


if [ ! -e "/var/run/docker.sock" ]; then
  echo "=> Cannot find docker socket(/var/run/docker.sock), please check the command!"
  exit 1
fi

if docker version >/dev/null; then
  echo "docker is running properly, starting cleanup"
else
  echo "Cannot run docker binary at /usr/bin/docker"
  echo "Please check if the docker binary is mounted correctly"
  exit 1
fi

if ! [[ "$CLEAN_PERIOD" =~ ^[0-9]+$ ]]; then
  echo "=> CLEAN_PERIOD not defined, use the default value."
  CLEAN_PERIOD=1800
fi

if [ "${LOOP}" != "false" ]; then
  LOOP=true
fi

if [ "${PRETEND}" != "false" ]; then
  PRETEND=true
fi

if [ "${DEBUG}" == "0" ]; then
  unset DEBUG
fi

trap '{ echo "User Interupt."; exit 1; }' SIGINT
trap '{ echo "SIGTERM received, exiting."; exit 0; }' SIGTERM

while [ 1 ]
do

  # get all terminated containers
  TERMINATED=$(docker ps -a -q -f status=exited -f status=dead)
  if [ $DEBUG ]; then echo -e "Terminated container IDs\n$TERMINATED"; fi

  # handle all terminated containers
  for CONTAINER_ID in $TERMINATED; do
    CONTAINER_NAME=$(docker inspect --format='{{(index .Name)}}' $CONTAINER_ID | sed -e 's/^\s*\/\(.*\)$/\1/g')
    LABELS=$(docker inspect --format='{{.Config.Labels}}' $CONTAINER_ID)
    # check if container belongs to a stack
    if [[ ${LABELS} == *"io.rancher.stack.name:"* ]]; then
      if [ $DEBUG ]; then echo "Keeping terminated container $CONTAINER_NAME since it is contained in a stack"; fi
    else
      if [ $DEBUG ]; then echo "Removing terminated standalone container $CONTAINER_NAME"; fi
      [ "${PRETEND}" == "true" ] || docker rm $CONTAINER_NAME
    fi
  done
  unset CONTAINER_ID
  
  # remove dangling volumes
  VOLUMES=$(docker volume ls -qf dangling=true)
  if [ $DEBUG ]; then 
    echo "Removing dangling volumes"
    echo $VOLUMES
  fi
  [ "${PRETEND}" == "true" ] || echo $VOLUMES | xargs -r docker volume rm

  # remove dangling images
  IMAGES=$(docker images -qf dangling=true)
  if [ $DEBUG ]; then 
    echo "Removing dangling images"
    echo $IMAGES
  fi
  [ "${PRETEND}" == "true" ] || echo $IMAGES | xargs -r docker rmi

  # Run forever or exit after the first run depending on the value of $LOOP
  [ "${LOOP}" == "true" ] || break

  echo "=> Next clean will be started in ${CLEAN_PERIOD} seconds"
  sleep ${CLEAN_PERIOD} & wait
done
