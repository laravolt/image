#!/usr/bin/env bash
# Installs a pinned Trivy release and checks it against a recorded SHA-256.
# Trivy's release tags and trivy-action were hijacked in March 2026
# (GHSA-69fq-xp46-6x23), so a tag alone is not trusted.
set -euo pipefail

version=0.76.0
sha256=e24b1c51293c1b15e4ba8d45bbc7891ba053f90278ec2698f3562c993e145fe7

curl -fsSLo /tmp/trivy.tgz \
  "https://github.com/aquasecurity/trivy/releases/download/v${version}/trivy_${version}_Linux-64bit.tar.gz"
echo "${sha256}  /tmp/trivy.tgz" | sha256sum -c -
sudo tar -xzf /tmp/trivy.tgz -C /usr/local/bin trivy
trivy --version
