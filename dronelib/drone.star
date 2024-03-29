def main(ctx):

  default_herzner_images = [
    "debian-10",
    "debian-11",
    "ubuntu-18.04",
    "ubuntu-20.04"
  ]
  default_docker_images = [
    "debian9",
    "debian10",
    "debian11",
    "ubuntu1804",
    "ubuntu2004",
  ]
  use_hetzner = getattr(ctx.input,"use_hetzner",False)
  hetzner_images = getattr(ctx.input,"hetzner_images", default_herzner_images)
  docker_images = getattr(ctx.input,"docker_images", default_docker_images)

  ############################################################################

  pipelines = [
    step_lint(),
  ]
  oses = hetzner_images if use_hetzner else docker_images
  for os in oses:
    if use_hetzner:
      pipelines.append(step_hetzner(os))
    else:
      pipelines.append(step_docker(os))

  if ctx.build.event == "tag":
    pipelines.append(step_publish(oses))
  return pipelines

def step_lint():
  return {
    "kind": "pipeline",
    "name": "linter",
    "steps": [
      {
        "name": "Lint",
        "image": "veselahouba/molecule",
        "commands": [
          "shellcheck_wrapper",
          "flake8",
          "yamllint .",
          "ansible-lint"
        ]
      }
    ]
  }

def step_docker(os):
  return {
    "kind": "pipeline",
    "depends_on": [
        "linter",
    ],
    "name": "molecule-%s" % os,
    "services": [
      {
        "name": "docker",
        "image": "docker:dind",
        "privileged": True,
        "volumes": [
          {
            "name": "dockersock",
            "path": "/var/run"
          },
          {
            "name": "sysfs",
            "path": "/sys/fs/cgroup"
          }
        ]
      }
    ],
    "volumes": [
      {
        "name": "dockersock",
        "temp": {}
      },
      {
        "name": "sysfs",
        "host": {
          "path": "/sys/fs/cgroup"
        }
      }
    ],
    "steps": [
      {
        "name": "Molecule test",
        "image": "veselahouba/molecule",
        "privileged": True,
        "volumes": [
          {
            "name": "dockersock",
            "path": "/var/run"
          },
          {
            "name": "sysfs",
            "path": "/sys/fs/cgroup"
          }
        ],
        "commands": [
          "sleep 30",
          "docker ps -a",
          "ansible --version",
          "molecule --version",
          "MOLECULE_IMAGE=geerlingguy/docker-%s-ansible" % os,
          "export MOLECULE_IMAGE",
          "mkdir -p ci",
          "curl https://raw.githubusercontent.com/VeselaHouba/molecule/master/molecule-docker/pull_files.sh > ci/pull_files.sh",
          "/bin/bash ci/pull_files.sh",
          "molecule test --all"
        ]
      },
      {
        "name": "Slack notification",
        "image": "plugins/slack",
        "settings": {
          "webhook": {
            "from_secret": "slack_webhook"
          },
          "channel": "ci-cd",
          "template": "Molecule for `{{build.branch}}` failed. {{build.link}}"
        },
        "when": {
          "status": [
            "failure"
          ]
        }
      }
    ]
  }

def step_hetzner(os):
  return {
    "kind": "pipeline",
    "depends_on": [
        "linter",
    ],
    "name": "molecule-%s" % os,
    "steps": [
      {
        "name": "Molecule test",
        "image": "veselahouba/molecule",
        "environment": {
          "HCLOUD_TOKEN": {
            "from_secret": "HCLOUD_TOKEN"
          }
        },
        "commands": [
          "ansible --version",
          "molecule --version",
          "REF=$$(echo $DRONE_COMMIT_SHA | cut -b -7)",
          "REPO_NAME=$$(echo $DRONE_REPO_NAME | sed 's/_/-/g')",
          "MOLECULE_IMAGE=%s" % os,
          "OS_VERSION=%s" % os.replace('.','-'),
          "export MOLECULE_IMAGE OS_VERSION REPO_NAME REF",
          "mkdir -p ci",
          "curl https://raw.githubusercontent.com/VeselaHouba/molecule/master/molecule-hetznercloud/pull_files.sh > ci/pull_files.sh",
          "/bin/bash ci/pull_files.sh",
          "molecule test --all"
        ]
      }
    ]
  }

def step_publish(oses):
  deps = []
  for os in oses:
    deps.append("molecule-%s" % os)
  return {
    "kind": "pipeline",
    "depends_on": deps,
    "name": "publish",
    "steps": [
        {
          "name": "Publish to Galaxy",
          "image": "veselahouba/molecule",
          "environment": {
            "GALAXY_API_KEY": {
              "from_secret": "GALAXY_API_KEY"
            }
          },
          "commands": [
            "ansible-galaxy role import --api-key $${GALAXY_API_KEY} $${DRONE_REPO_OWNER} $${DRONE_REPO_NAME} --branch $${DRONE_TAG}"
          ]
        },
        {
          "name": "Slack notification",
          "image": "plugins/slack",
          "settings": {
            "webhook": {
              "from_secret": "slack_webhook"
            },
            "channel": "ci-cd",
            "template":
              "{{#success build.status}}" +
                  "Publish for `{{build.tag}}` succeeded." +
                  "{{build.link}}" +
                "{{else}}" +
                  "Publish for `{{build.tag}}` failed." +
                  "{{build.link}}"+
              "{{/success}}"
          },
          "when": {
            "status": [
              "success",
              "failure"
            ]
          }
        }
    ]
  }
