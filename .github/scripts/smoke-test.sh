#!/usr/bin/env bash
# Checks a runtime image before it is pushed.
# Usage: smoke-test.sh <image> <php-version>
set -euo pipefail

image=$1
php=$2

echo "PHP $(docker run --rm --entrypoint php "$image" -r 'echo PHP_VERSION;')"
actual=$(docker run --rm --entrypoint php "$image" -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
test "$actual" = "$php"

docker run --rm --entrypoint php "$image" -m \
  | grep -E '^(bcmath|exif|gd|intl|pdo_sqlsrv|sqlsrv|zip)$' | sort | tee /tmp/ext.txt
test "$(wc -l < /tmp/ext.txt)" -eq 7

# Session upload progress stays off (CVE-2026-109619, CVE-2026-115560).
docker run --rm --entrypoint php "$image" -r 'exit(ini_get("session.upload_progress.enabled") ? 1 : 0);'

# No world-writable files or non-sticky directories (GHSA-xx74-jh2r-mgm3).
writable=$(docker run --rm --user root --entrypoint sh "$image" \
  -c 'find / -xdev -perm -0002 \( -type d ! -perm -1000 -o -type f \) -print')
if [ -n "$writable" ]; then
  echo "World-writable paths:"
  echo "$writable"
  exit 1
fi

# GnuPG is only used while building; it is removed again (CVE-2026-24882).
if docker run --rm --entrypoint sh "$image" -c 'command -v gpg'; then
  echo "gpg is still installed"
  exit 1
fi

# The web server starts as the default user and answers its health check.
cid=$(docker run -d -p 127.0.0.1:8080:8080 "$image")
trap 'docker rm -f "$cid" > /dev/null' EXIT
for _ in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:8080/healthcheck; then
    echo
    exit 0
  fi
  sleep 1
done
docker logs "$cid"
exit 1
