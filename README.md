# sample-golden-image

The platform team's "golden" image: hardened Ubuntu base

## Configuration

| Setting  | Value                         |
| -------- | ----------------------------- |
| Provider | `aws` |
| Base OS  | `ubuntu-22.04`       |
| Region   | `us-east-1`        |
| Size     | `t3.medium` |

The values are defaults of variables in `image.pkr.hcl`; override them with
`-var name=value`.

## Build locally

```bash
packer init .
packer validate .
packer build .
```

Packer uses the AWS credentials of your shell (`aws configure`, `aws sso login`
or `AWS_*` environment variables).

## Provisioning

`scripts/provision.sh` installs the software baked into the image.

## Pipeline

`.github/workflows/packer.yaml` runs on every push and pull request:

| Job                       | What it does                                                    |
| ------------------------- | --------------------------------------------------------------- |
| Validate                  | `packer fmt -check`, `packer init`, `packer validate`           |
| Lint provisioning scripts | `bash -n` and ShellCheck on `scripts/`                          |
| Secret scan               | Trivy looks for committed credentials                           |
| Build image               | `packer build`, only on `main` and only once credentials exist  |

The build is skipped until these repository secrets are set:

- `AWS_ROLE_ARN`: IAM role the workflow assumes through GitHub OIDC.
