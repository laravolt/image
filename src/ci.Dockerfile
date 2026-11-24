# CI image for Laravolt Laravel projects.
# PHP 8.5 CLI + Composer + Bun + Node.js LTS + Playwright Chromium.
# Published to Docker Hub as laravoltdev/image:php8.5-ci
#
# Built on the ServerSideUp PHP CLI image (Debian 13 trixie), the same release
# as the runtime image. Until 23 Nov 2026 it was Ubuntu 24.04 with PHP from the
# ondrej/php PPA, whose download server failed three weekly publishes in a row.
#
# Does NOT include: FrankenPHP, sqlsrv, or runtime server components.
# Use the runtime image (laravoltdev/image:php8.5-prod) for deployments.

ARG PHP_VERSION=8.5
# ServerSideUp release, kept equal to src/Dockerfile (update-base-image bumps both).
ARG SERVERSIDEUP_VERSION='v5.2.1'

FROM serversideup/php:${PHP_VERSION}-cli-trixie-${SERVERSIDEUP_VERSION}

USER root
# PHP_MEMORY_LIMIT: CLI tools in CI (PHPStan, Pest) need more than the base
# image's 256M; -1 matches the CLI default of the Ubuntu-based image.
ENV DEBIAN_FRONTEND=noninteractive \
    PLAYWRIGHT_BROWSERS_PATH=/root/.cache/ms-playwright \
    PHP_MEMORY_LIMIT=-1

ARG PHP_VERSION
ARG COMPOSER_VERSION=2.10.3
ARG BUN_VERSION=1.4.3
ARG NODE_MAJOR=24
ARG PLAYWRIGHT_VERSION=1.64.1

# Extensions required by Laravolt projects, built by install-php-extensions from
# the base image (Debian packages + PECL, no PPA). pcov replaces xdebug as the
# coverage driver (lighter, no "zend_mm_heap corrupted" crashes with
# pest --type-coverage). sqlite3 for in-memory test databases. No sqlsrv: tests
# use SQLite. Pending Debian security updates are applied first.
RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && apt-get install -y --no-install-recommends ca-certificates curl git unzip sqlite3 \
    && install-php-extensions bcmath gd intl pcov sockets zip pdo_sqlite \
    && rm -rf /var/lib/apt/lists/* \
    && php -v \
    && test "$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')" = "${PHP_VERSION}" \
    && for ext in bcmath gd intl pcov sockets zip pdo_sqlite; do php -m | grep -qx "$ext" || exit 1; done \
    && ! php -m | grep -qi xdebug

# Composer (pinned version)
RUN curl -fsSL -o /usr/local/bin/composer \
        "https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar" \
    && chmod +x /usr/local/bin/composer \
    && composer --version

# Node.js LTS, required by the Pest browser plugin (Playwright runtime).
# Bun alone cannot run Playwright's server process reliably.
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && node --version && npm --version

# Bun (frontend build tool, pinned version)
RUN curl -fsSL https://bun.sh/install | bash -s "bun-v${BUN_VERSION}" \
    && ln -sf /root/.bun/bin/bun /usr/local/bin/bun \
    && ln -sf /root/.bun/bin/bunx /usr/local/bin/bunx \
    && bun --version

# Playwright Chromium + system dependencies (pinned version).
# Uses npx to ensure Node.js-compatible browser path.
# /etc/playwright-version records which Playwright the browsers belong to; a
# project's `playwright` npm package should use the same version.
RUN npx playwright@${PLAYWRIGHT_VERSION} install --with-deps chromium \
    && rm -rf /var/lib/apt/lists/* \
    && ls "${PLAYWRIGHT_BROWSERS_PATH}" \
    && echo "${PLAYWRIGHT_VERSION}" > /etc/playwright-version

RUN rm -rf /tmp/* /var/tmp/*

# Plain shell like the Ubuntu-based image: no ServerSideUp entrypoint, root user.
ENTRYPOINT []
CMD ["/bin/bash"]

LABEL org.opencontainers.image.title="laravolt-ci" \
      org.opencontainers.image.description="CI image for Laravolt projects (Debian 13): PHP ${PHP_VERSION} (pcov), Composer ${COMPOSER_VERSION}, Node.js ${NODE_MAJOR}.x, Bun ${BUN_VERSION}, Playwright ${PLAYWRIGHT_VERSION} Chromium"
