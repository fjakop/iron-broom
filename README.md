<img src="https://github.com/fjakop/iron-broom/blob/master/rancher/catalog/templates/iron-broom/catalogIcon-iron-broom.png" width="100">

# Iron Broom

Cleanup docker containers, volumes and images in a [Rancher](http://rancher.com/) infrastructure.

This image will periodically clean up exited standalone containers and remove images and volumes that aren't in use by any container (a.k.a 'dangling'). If a container is part of a stack it will be left alone, as stack-managed containers should be started, stopped & removed by the stack.

Normally any Docker containers that exit are still kept on disk until `docker rm -v` is used to clean them up. Similarly any images that aren't used any more are kept around. For a cluster node that see lots of containers start and stop, large amounts of exited containers and old image versions can fill up the disk. A Gitlab CI multi runner starts a lot of containers and leaves them around.

# Flow

* find all terminated containers on the host
* select containers without `io.rancher.stack.name` label
* delete them
* delete dangling volumes & images

# Environment Variables

The default parameters can be overridden by setting environment variables on the container using the docker run -e flag.

`CLEAN_PERIOD` (integer, default `1800`) sleep seconds between cleanup runs

`DEBUG` (boolean, default `false`) debug output

`PRETEND` (boolean, default `true`) do not actually delete, just do a dry-run and log

`LOOP` (boolean, default `true`) for testing purposes - execute just once and exit

# Deployment

This image is deployed best via Rancher catalog. Appropriate `docker-compose.yml` and `rancher-compose.yml` are included in catalog subfolder.

The image uses the Docker client to to list and remove containers and images. For this reason the Docker client and socket is mapped into the container.



This tool was inspired by https://github.com/meltwater/docker-cleanup
