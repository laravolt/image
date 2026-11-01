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

Every release also publishes versioned tags such as `php8.5-prod-v2.0.0` and `php8.5-dev-v2.0.0`. Pin a versioned tag in production. The plain tags follow `main`. They are rebuilt whenever `src/` changes, and every Monday so that Debian security updates reach them.

Every image is built for `linux/amd64` and `linux/arm64`, so it runs natively on Apple Silicon. The CI image is built on native arm64 runners. Each image ships with SBOM and provenance attestations.

## What is inside

PHP extensions added on top of ServerSideUp:

- `bcmath`, `exif`, `gd`, `intl`
- `pdo_sqlsrv` and `sqlsrv` (Microsoft SQL Server, with `msodbcsql18`)

ServerSideUp already provides `zip`, the PDO drivers for MySQL, PostgreSQL and SQLite, Redis, and OPcache.

The base is ServerSideUp **v5** (`SERVERSIDEUP_VERSION` in `src/Dockerfile`).

The dev image adds Bun and Xdebug. Xdebug is off by default; turn it on with `XDEBUG_MODE=debug` or `XDEBUG_MODE=coverage`.

## Use it

### Production

```dockerfile
FROM laravoltdev/image:php8.5-prod-v2.0.0

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

## Security

Before anything is pushed, every runtime image goes through these checks:

- **PHP and extensions.** The PHP version (the full patch version is printed in the log) and the extensions listed above are checked.
- **No world-writable files** outside sticky directories such as `/tmp`. ServerSideUp v4.3.1 to v5.0.4 shipped a world-writable Caddyfile ([GHSA-xx74-jh2r-mgm3](https://github.com/serversideup/docker-php/security/advisories/GHSA-xx74-jh2r-mgm3)).
- **Session upload progress is off** (`session.upload_progress.enabled`), until PHP fixes CVE-2026-115560. Laravel does not use it.
- **Trivy scan.** A critical vulnerability with a fix available stops the push. The full HIGH and CRITICAL report goes to the repository's Security tab.
- **Pending Debian security updates** are installed at build time.

The weekly rebuild keeps the plain tags patched. A workflow opens a PR when ServerSideUp publishes a newer release in the same major version, once it is 14 days old. Dependabot keeps the GitHub Actions current.

## Upgrading from v1 (ServerSideUp v4)

v2 moves the base to ServerSideUp v5. Most apps need no change. Check these points:

- **A failed autorun step stops the container.** For example, `storage:link` fails when `public/` belongs to root. ServerSideUp v4 let that pass. Create the link in your Dockerfile, as root (`php artisan storage:link`), or set `AUTORUN_LARAVEL_STORAGE_LINK=false`. The autorun skips a link that already exists.
- **FrankenPHP logs** go to `stderr`. The format is JSON when there is no terminal. Set `CADDY_LOG_FORMAT=console` if something parses the old lines.
- **`TRUSTED_PROXY`** defaults to `cloudflare`. Behind your own load balancer or reverse proxy, set `TRUSTED_PROXY=local` so the app sees the real client IP.
- **OPcache:** with `PHP_OPCACHE_ENABLE=1`, files are no longer re-checked (`PHP_OPCACHE_VALIDATE_TIMESTAMPS=0`). This is fine for a baked image. If you mount code, set it back to `1`.
- **Requests with more than 16 KiB of headers** get a 431. Large cookies are the usual cause.
- **Laravel Octane** can use the image's Caddyfile: `php artisan octane:start --server=frankenphp --port=8080 --caddyfile=/etc/frankenphp/Caddyfile`.
- **The dev image** sets `AUTORUN_LARAVEL_SKIP_IF_NOT_FOUND=true`, so it starts even before a project is mounted.

The [ServerSideUp v5 release notes](https://github.com/serversideup/docker-php/releases/tag/v5.0.0) and [migration guide](https://serversideup.net/open-source/docker-php/docs/guide/major-version-migrations) cover the rest.

## Build locally

You should not need to, but:

```bash
docker build \
  --build-arg PHP_VERSION=8.5 \
  --build-arg BASE_VARIATION=frankenphp-debian \
  -t laravoltdev/image:php8.5-prod \
  src

docker build -f src/dev.Dockerfile --build-arg BASE_IMAGE=laravoltdev/image:php8.5-prod -t laravoltdev/image:php8.5-dev src
```

## Releasing

1. Merge to `main`. The plain tags are rebuilt and pushed after the checks in [Security](#security). Pull requests run the same checks, and also build laravel-starter-kit's production image on top of the new image and load its login page.
2. Publish a GitHub release (`vX.Y.Z`). The same workflow builds the release tag and pushes the versioned tags and `latest`.
