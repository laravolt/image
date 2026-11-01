#!/usr/bin/env bash
# Scans an image with Trivy for HIGH and CRITICAL vulnerabilities.
#
# - The log lists every one, whether or not a fix exists yet.
# - The SARIF report (for the Security tab) lists only those with a fix, so
#   every alert there is something a rebuild or an upgrade can resolve.
# - The job summary lists the ones still waiting for a fix upstream.
# - The scan fails when a CRITICAL vulnerability has a fix available.
#
# Kernel header CVEs are not counted; trivy-ignore.rego says why.
# Usage: scan.sh <image> [sarif-file]
set -euo pipefail

image=$1
sarif=${2:-}
policy="$(dirname "$0")/trivy-ignore.rego"

scan() {
  trivy image --scanners vuln --ignore-policy "$policy" "$@" "$image"
}

scan --severity HIGH,CRITICAL \
  --db-repository ghcr.io/aquasecurity/trivy-db:2,public.ecr.aws/aquasecurity/trivy-db:2

if [ -n "$sarif" ]; then
  scan --severity HIGH,CRITICAL --ignore-unfixed --skip-db-update \
    --format sarif --output "$sarif"
fi

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  report=$(mktemp)
  scan --severity HIGH,CRITICAL --skip-db-update --format json --output "$report" --quiet
  jq -r --arg image "$image" '
    [.Results[]?.Vulnerabilities[]?]
    | group_by(.VulnerabilityID)
    | map({
        id: .[0].VulnerabilityID,
        url: (.[0].PrimaryURL // ""),
        severity: .[0].Severity,
        fixed: (map(.FixedVersion // "") | map(select(. != "")) | unique | join(", ")),
        packages: (map(.PkgName) | unique | join(", "))
      })
    | sort_by(.severity != "CRITICAL", .fixed == "", .id) as $rows
    | ($rows | map(select(.fixed == "")) | length) as $waiting
    | "### Trivy: `\($image)`\n",
      if ($rows | length) == 0 then
        "No HIGH or CRITICAL vulnerabilities.\n"
      else
        "\($rows | length) HIGH or CRITICAL vulnerabilities, \($waiting) of them with no fix released yet. The weekly rebuild installs Debian fixes as they come out.\n",
        "| Severity | Vulnerability | Packages | Fixed in |",
        "|---|---|---|---|",
        ($rows[] | "| \(.severity) | \(if .url != "" then "[\(.id)](\(.url))" else .id end) | \(.packages) | \(if .fixed != "" then .fixed else "no fix yet" end) |"),
        ""
      end
  ' "$report" >> "$GITHUB_STEP_SUMMARY"
  rm -f "$report"
fi

scan --severity CRITICAL --ignore-unfixed --skip-db-update --exit-code 1
