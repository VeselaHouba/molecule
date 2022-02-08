def main(ctx):

  default_hetzner_images = [
    "debian-10",
    "debian-11",
    "ubuntu-18.04",
    "ubuntu-20.04"
  ]
  hetzner_images = getattr(ctx.input,"hetzner_images", default_hetzner_images)

  ############################################################################

  pipelines = [
    step_lint(),
  ]
  oses = hetzner_images
  for os in oses:
    pipelines.append(step_hetzner(os))
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
