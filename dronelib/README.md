# Drone templates
Templates are imported to drone.io instance

More info
https://docs.drone.io/template/starlark/

Example for quick import:

```
export DRONE_SERVER=## YOUR_SERVER ##
export DRONE_TOKEN=## YOUR_TOKEN ##

git clone https://github.com/VeselaHouba/molecule.git

docker run --rm -ti -v \
  $(pwd)/molecule/dronelib:/opt/dronelib \
  -e DRONE_SERVER \
  -e DRONE_TOKEN \
  debian:11 bash -c "
  apt update && \
  apt -y install curl && \
  curl -L https://github.com/drone/drone-cli/releases/latest/download/drone_linux_amd64.tar.gz | tar zx && \
  install -t /usr/local/bin drone && \
  bash"
```

Inside container:

```
drone template ls
drone template add --namespace veselahouba --name "drone.star" --data @/opt/dronelib/drone.star
```
