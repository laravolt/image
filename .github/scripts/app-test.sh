#!/usr/bin/env bash
# Builds laravel-starter-kit's production image on top of the runtime image
# under test, starts it, and checks that it serves the login page.
# Usage: app-test.sh <runtime-image>
set -euo pipefail

image=$1
app=$(mktemp -d)

git clone --depth 1 https://github.com/laravolt/laravel-starter-kit.git "$app"

# The kit builds FROM laravoltdev/image:php8.5-prod. Point that tag at the
# image under test; nothing is pushed from this job.
docker tag "$image" laravoltdev/image:php8.5-prod
docker build --file "$app/docker/frankenphp/prod.Dockerfile" --tag starter-kit-check "$app"

cid=$(docker run -d -p 127.0.0.1:8090:8080 \
  -e APP_KEY="base64:$(openssl rand -base64 32)" \
  -e APP_URL=http://127.0.0.1:8090 \
  -e APP_FORCE_HTTPS=false \
  starter-kit-check)
trap 'docker rm -f "$cid" > /dev/null' EXIT

for _ in $(seq 1 60); do
  if curl -fsS http://127.0.0.1:8090/auth/login | grep -q 'name="email"'; then
    echo "laravel-starter-kit serves its login page"
    exit 0
  fi
  sleep 2
done
docker logs "$cid"
exit 1
