#!/usr/bin/env bash
# Scans an image with Trivy. Prints every HIGH and CRITICAL vulnerability, and
# fails when a CRITICAL one has a fix available.
# Usage: scan.sh <image> [sarif-file]
set -euo pipefail

image=$1
sarif=${2:-}

trivy image --scanners vuln --severity HIGH,CRITICAL \
  --db-repository ghcr.io/aquasecurity/trivy-db:2,public.ecr.aws/aquasecurity/trivy-db:2 \
  "$image"

if [ -n "$sarif" ]; then
  trivy image --scanners vuln --severity HIGH,CRITICAL --skip-db-update \
    --format sarif --output "$sarif" "$image"
fi

trivy image --scanners vuln --severity CRITICAL --ignore-unfixed --skip-db-update \
  --exit-code 1 "$image"
