def main(ctx):

  default_docker_images = [
    "debian9",
    "debian10",
    "debian11",
    "ubuntu1804",
    "ubuntu2004",
  ]
  docker_images = getattr(ctx.input,"docker_images", default_docker_images)

  ############################################################################

  pipelines = [
    step_lint(),
  ]
  oses = docker_images
  for os in oses:
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
