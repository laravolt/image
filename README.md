[![Release](https://img.shields.io/github/v/release/laravolt/image)](https://github.com/laravolt/image/releases)

# laravoltdev/image

Ready-made Docker images for Laravolt 8 applications, published to Docker Hub: <https://hub.docker.com/r/laravoltdev/image>.

Pull instead of building: every laptop, CI runner and server uses the same image, built once by this repository's GitHub Actions. The images extend [ServerSideUp PHP](https://serversideup.net/open-source/docker-php/) (FrankenPHP on Debian) and add the PHP extensions Laravolt needs.

## Tags

| Tag | Use it for |
| --- | --- |
| `php8.5-prod` (also `php8.5-frankenphp-debian`, `php8.5-base`, `latest`) | Production: copy your app into it in your own Dockerfile |
| `php8.5-dev` | Local development: mount your project, no build step |
| `php8.5-ci` | CI pipelines: PHP CLI with pcov, Composer, Node.js, Bun and Playwright Chromium. `/etc/playwright-version` names the Playwright version the browsers belong to |
| `php8.4-*`, `php8.3-*` | The same runtime and dev images on PHP 8.4 and 8.3 |

Every release also publishes versioned tags such as `php8.5-prod-v1.2.0` and `php8.5-dev-v1.2.0`. Pin a versioned tag in production. The plain tags follow `main` and are rebuilt whenever `src/` changes.

Every image is built for `linux/amd64` and `linux/arm64`, so it runs natively on Apple Silicon. The CI image is built on native arm64 runners. Each image ships with SBOM and provenance attestations.

## What is inside

PHP extensions added on top of ServerSideUp:

- `bcmath`, `exif`, `gd`, `intl`
- `pdo_sqlsrv` and `sqlsrv` (Microsoft SQL Server, with `msodbcsql18`)

ServerSideUp already provides `zip`, the PDO drivers for MySQL, PostgreSQL and SQLite, Redis, and OPcache.

The dev image adds Bun and Xdebug. Xdebug is off by default; turn it on with `XDEBUG_MODE=debug` or `XDEBUG_MODE=coverage`.

## Use it

### Production

```dockerfile
FROM laravoltdev/image:php8.5-prod-v1.2.0

COPY --chown=www-data:www-data . /var/www/html
RUN composer install --no-dev --optimize-autoloader
```

### Local development

```yaml
# docker-compose.yml
services:
  app:
    image: laravoltdev/image:php8.5-dev
    ports:
      - "8080:8080"   # app
      - "5173:5173"   # Vite (run `bun run dev` inside the container)
    volumes:
      - .:/var/www/html
```

```bash
docker compose up -d
docker compose exec app composer install
docker compose exec app bun install
docker compose exec app bun run dev
```

## Laravolt entrypoint hook

When these are set, the container runs `php artisan laravolt:link` on start. The dev image sets them by default.

```env
AUTORUN_ENABLED=true
AUTORUN_LARAVOLT_LINK=true
APP_BASE_DIR=/var/www/html
```

The hook is safe to skip: if Laravel or Laravolt is not installed, it exits without failing the container.

## Build locally

You should not need to, but:

```bash
docker build \
  --build-arg PHP_VERSION=8.5 \
  --build-arg BASE_VARIATION=frankenphp-debian \
  --build-arg SERVERSIDEUP_VERSION=v4.5.1 \
  -t laravoltdev/image:php8.5-prod \
  src

docker build -f src/dev.Dockerfile --build-arg BASE_IMAGE=laravoltdev/image:php8.5-prod -t laravoltdev/image:php8.5-dev src
```

## Releasing

1. Merge to `main`. The plain tags are rebuilt and pushed after a smoke test: the PHP version and every extension above are checked before anything is pushed.
2. Publish a GitHub release (`vX.Y.Z`). The same workflow builds the release tag and pushes the versioned tags and `latest`.
