#!/usr/bin/env bash
# Pulls the linux/amd64 and linux/arm64 images of a multi-platform digest and
# tags them <prefix>-amd64 and <prefix>-arm64, for the smoke test and the scans.
#
# The runner's image store cannot pull one index digest for two platforms
# ("cannot overwrite digest"), and a tag on the index would not say which
# platform a scan reads. So each platform is pulled by its own manifest digest.
# Usage: pull-platforms.sh <repo@sha256:index-digest> <prefix>
set -euo pipefail

ref=$1
prefix=$2
repo=${ref%@*}

index=$(docker buildx imagetools inspect --raw "$ref")
for arch in amd64 arm64; do
  digest=$(jq -er --arg arch "$arch" '
    [.manifests[] | select(.platform.os == "linux" and .platform.architecture == $arch)]
    | if length == 1 then .[0].digest
      else error("expected one linux/\($arch) manifest, found \(length)") end
  ' <<<"$index")
  docker pull --platform "linux/$arch" "$repo@$digest"
  docker tag "$repo@$digest" "$prefix-$arch"
done
