# sample-golden-image

The platform team's "golden" image: hardened Ubuntu base

## Overview

This repository builds an immutable machine image with
[Packer](https://developer.hashicorp.com/packer). Every build starts from a
clean `ubuntu-22.04` base image, installs the software listed in the
provisioning script and registers the result as a new image, so that machines
are replaced rather than patched in place.

```d2
direction: right

base: Base image {
  label: "ubuntu-22.04"
  shape: package
  style.fill: "#E3F2FD"
  style.stroke: "#1976D2"
}

packer: Packer {
  style.fill: "#E8F5E9"
  style.stroke: "#388E3C"

  init: packer init
  validate: packer validate
  build: packer build

  init -> validate -> build
}

provision: Provisioning {
  label: "scripts/provision.sh"
  shape: document
  style.fill: "#FFF3E0"
  style.stroke: "#FF9800"
}

image: New image {
  label: "sample-golden-image-<timestamp>"
  shape: hexagon
  style.fill: "#FCE4EC"
  style.stroke: "#C2185B"
}

base -> packer.build: temporary build machine
packer.build -> provision: runs
provision -> image: captured as
```

---

## Configuration Summary

| Setting        | Value                          |
| -------------- | ------------------------------ |
| Image name     | `sample-golden-image`           |
| Provider       | `aws` |
| Base OS        | `ubuntu-22.04`        |
| Region         | `us-east-1`         |
| Build size     | `t3.medium`  |
| Docker         | installed |
| Ansible        | not installed |
| Owner          | `group:default/platform-team`          |

---

## Repository Structure

```
sample-golden-image/
├── .github/workflows/packer.yaml   # Validation and build pipeline
├── docs/index.md                   # This documentation
├── scripts/
│   └── provision.sh                # Software installed into the image
├── image.pkr.hcl                   # Packer template: plugin, variables, source, build
├── catalog-info.yaml               # Backstage catalog entry
├── mkdocs.yml                      # TechDocs configuration
└── README.md
```

---

## CI/CD Pipeline

`.github/workflows/packer.yaml` runs on every push to `main`, on pull requests
and on demand.

| Job                       | What it does                                                   | Needs credentials |
| ------------------------- | -------------------------------------------------------------- | ----------------- |
| Validate                  | `packer fmt -check`, `packer init`, `packer validate`          | No                |
| Lint provisioning scripts | `bash -n` and ShellCheck on `scripts/`                         | No                |
| Secret scan               | Trivy looks for committed credentials                          | No                |
| Build image               | `packer build` on `main` and on manual runs                    | Yes               |

The build job is skipped, not failed, while its credentials are missing. Add
these repository secrets to turn it on:

| Secret         | Purpose                                                    |
| -------------- | ---------------------------------------------------------- |
| `AWS_ROLE_ARN` | IAM role the workflow assumes through GitHub OIDC          |

The role needs the
[permissions Packer documents for the Amazon EBS builder](https://developer.hashicorp.com/packer/integrations/hashicorp/amazon#iam-task-or-instance-role)
and a trust policy for `token.actions.githubusercontent.com` restricted to this
repository.

---

## Building Locally

Install Packer 1.9 or later, then:

```bash
packer init .
packer fmt -check .
packer validate .
packer build .
```

Packer uses the AWS credentials of your shell: `aws sso login`, a profile in
`AWS_PROFILE`, or `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

### Variables

Every setting chosen when this repository was created is the default of a
variable in `image.pkr.hcl`. Override one for a single build with `-var`:

```bash
packer build -var image_name=sample-golden-image-test .
```

Each image is named `<image_name>-<UTC timestamp>`, and the build writes the
identifier of the new image to `manifest.json`.

---

## Changing What Is Installed

Edit `scripts/provision.sh`. It runs as root on the temporary build machine and
stops at the first failing command.

Keep secrets out of the script and out of the image: anything written to disk
during a build is readable by everyone who can launch the image.

---

## Troubleshooting

| Symptom                                   | Cause and fix                                                         |
| ----------------------------------------- | --------------------------------------------------------------------- |
| `packer init` is rate limited             | Set `PACKER_GITHUB_API_TOKEN` to a GitHub token                       |
| `packer fmt -check` fails in the pipeline | Run `packer fmt .` and commit the result                              |
| Build waits for SSH until it times out    | The build machine must accept inbound TCP 22 from where Packer runs   |
| Build job is skipped                      | The secrets listed under CI/CD Pipeline are not set                   |

Run a build with `PACKER_LOG=1` for a detailed log, and with `-on-error=ask` to
keep the build machine for inspection when a provisioner fails.

---

## References

- [Packer documentation](https://developer.hashicorp.com/packer/docs)
- [Packer integrations](https://developer.hashicorp.com/packer/integrations)
- [setup-packer GitHub Action](https://github.com/hashicorp/setup-packer)
