# Molecule
## Drone template

### Data variables
- `use_hetzner=false` : implicating default driver `docker`
- `hetzner_images` : List of images, default list is in `dronelib/drone.star`
- `docker_images` : List of images, default list is in `dronelib/drone.star`


### Examples

Basic example. Default driver is `docker`

```
kind: template
load: drone.star
```

Hetzner example with custom list of images

```
kind: template
load: drone.star
data:
  use_hetzner: true
  hetzner_images:
    - debian-10
    - debian-11
    - ubuntu-18.04
    - ubuntu-20.04
```

Docker example with custom list of images
```
kind: template
load: drone-docker.star

data:
  docker_images:
    - debian10
    - debian11
    - ubuntu1804
    - ubuntu2004
```

Docker example with custom list of images, which generates matrix of all combinations of `server x client` from provided `docker_images`
```
kind: template
load: drone-docker-server-client-matrix.star

data:
  docker_images:
    - debian9
    - debian10
    - ubuntu1804
    - ubuntu2004
```
Images are provided to molecule as `MOLECULE_IMAGE_SERVER` and `MOLECULE_IMAGE_CLIENT` env variables

### Loading ansible variables

Append to converge:

```YAML
post_tasks:
  - name: dump
    changed_when: false
    copy:
      content: "{{ vars | to_yaml }}"
      dest: /tmp/ansible-vars.yml
```

Load in molecule test

```PYTHON
import yaml

...

stream = host.file('/tmp/ansible-vars.yml').content
ansible_vars = yaml.load(stream, Loader=yaml.FullLoader)
def_variable = ansible_vars['variable_name']
```
