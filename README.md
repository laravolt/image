[![Release](https://img.shields.io/github/v/release/laravolt/image)](https://github.com/laravolt/image/releases)

## Introduction

Reusable Docker base image for Laravolt/Laravel deployment. The image extends [ServerSideUp PHP](https://serversideup.net/open-source/docker-php/) and adds Laravolt-friendly PHP extensions plus a small entrypoint hook that can run `php artisan laravolt:link` during container startup.

## Published Images

Docker Hub: <https://hub.docker.com/r/laravoltdev/image>

Recommended tag for Laravolt v7 applications:

```bash
docker pull laravoltdev/image:php8.4-frankenphp-debian
```

Compatibility tags are kept for existing apps:

| Tag | Purpose |
| --- | --- |
| `laravoltdev/image:php8.4-frankenphp-debian` | Recommended PHP 8.4 FrankenPHP Debian runtime |
| `laravoltdev/image:php8.3-frankenphp-debian` | PHP 8.3 FrankenPHP Debian runtime |
| `laravoltdev/image:php8.4-base` | Backward-compatible alias for PHP 8.4 recommended runtime |
| `laravoltdev/image:php8.3-base` | Backward-compatible alias for PHP 8.3 recommended runtime |
| `laravoltdev/image:latest` | Latest recommended PHP runtime, currently PHP 8.4 |

Release builds also publish versioned tags such as `php8.4-frankenphp-debian-vX.Y.Z` and `php8.4-base-vX.Y.Z`.

## Included PHP Extensions

The image explicitly installs the extensions commonly needed by Laravolt v7 applications:

- `bcmath`
- `exif`
- `gd`
- `intl`

ServerSideUp already ships common Laravel runtime extensions such as `zip`, PDO database drivers, and Redis on the recommended FrankenPHP images. Keep those available through the upstream base instead of reinstalling them here.

## Laravolt Entrypoint Hook

Set these env vars to auto-run Laravolt asset linking when a Laravel app is mounted/baked into the image:

```env
AUTORUN_ENABLED=true
AUTORUN_LARAVOLT_LINK=true
APP_BASE_DIR=/var/www/html
```

The hook is safe to skip: if Laravel or Laravolt is not installed, it exits without failing the container.

## Build Locally

```bash
docker build \
  --build-arg PHP_VERSION=8.4 \
  --build-arg BASE_VARIATION=frankenphp-debian \
  --build-arg SERVERSIDEUP_VERSION=v4.4.0 \
  -t laravoltdev/image:php8.4-frankenphp-debian \
  src
```
