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

if ! [[ "$DECAY_TIME" =~ ^[0-9]+$ ]]; then
  echo "=> DECAY_TIME not defined, use the default value."
  DECAY_TIME=30
fi

if [ "${LOOP}" != "false" ]; then
  LOOP=true
fi

if [ "${PRETEND}" != "false" ]; then
  PRETEND=true
fi

if [ "${DEBUG}" == "false" ]; then
  unset DEBUG
fi

trap '{ echo "User Interupt."; exit 1; }' SIGINT
trap '{ echo "SIGTERM received, exiting."; exit 0; }' SIGTERM

while [ 1 ]
do

  # prune terminated containers without rancher stack exited longer than DECAY_TIME
  [ -n "$DEBUG" ] && echo "pruning terminated containers without rancher stack label exited longer than $DECAY_TIME minutes"
  [ "${PRETEND}" == "true" ] || docker container prune -f --filter "label!=io.rancher.stack.name" --filter "until=${DECAY_TIME}m"
  
  # prune unused volumes
  [ -n "$DEBUG" ] && echo "pruning dangling volumes"
  [ "${PRETEND}" == "true" ] || docker volume prune -f

  # remove dangling images
  [ -n "$DEBUG" ] && echo "pruning dangling images"
  [ "${PRETEND}" == "true" ] || docker image prune -f

  # Run forever or exit after the first run depending on the value of $LOOP
  [ "${LOOP}" == "true" ] || break

  echo "=> Next clean will be started in ${CLEAN_PERIOD} seconds"
  sleep ${CLEAN_PERIOD} & wait
done
