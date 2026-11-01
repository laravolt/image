#!/usr/bin/env bash
# Checks the CI image on the architecture it was built for.
# Usage: ci-smoke-test.sh <image>
set -euo pipefail

image=$1
run() { docker run --rm --entrypoint "" "$image" "$@"; }

run uname -m
run php -v
run php -m | grep -qx pcov
run php -m | grep -qx sockets
run composer --version
run node --version
run bun --version

# Chromium must actually start: render a page and save a screenshot.
run sh -c 'cd /tmp && npx --yes "playwright@$(cat /etc/playwright-version)" screenshot --browser chromium "data:text/html,<h1>ok</h1>" shot.png && test -s shot.png && echo "Chromium OK"'
