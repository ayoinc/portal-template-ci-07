#!/usr/bin/env bash
# Installs the software baked into the sample-golden-image image. Packer runs
# this as root on the temporary build machine.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Cloud images finish their own first-boot setup in the background; wait for
# it so that apt is not locked.
if command -v cloud-init >/dev/null 2>&1; then
  cloud-init status --wait || true
fi

apt-get update -y
apt-get install -y ca-certificates curl wget git

apt-get install -y curl
curl -fsSL https://get.docker.com | sh
systemctl enable docker

apt-get clean
rm -rf /var/lib/apt/lists/*
