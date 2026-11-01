# CI image for Laravolt Laravel projects.
# PHP 8.5 CLI + Composer + Bun + Node.js LTS + Playwright Chromium.
# Published to Docker Hub as laravoltdev/image:php8.5-ci
#
# Does NOT include: FrankenPHP, sqlsrv, or runtime server components.
# Use the runtime image (laravoltdev/image:php8.5-prod) for deployments.

FROM ubuntu:24.04

USER root
ENV DEBIAN_FRONTEND=noninteractive \
    PLAYWRIGHT_BROWSERS_PATH=/root/.cache/ms-playwright

ARG PHP_VERSION=8.5
ARG COMPOSER_VERSION=2.10.3
ARG BUN_VERSION=1.4.3
ARG NODE_MAJOR=24
ARG PLAYWRIGHT_VERSION=1.64.1

# PHP 8.5 CLI + extensions required by Laravolt projects.
# sockets is built into php8.5-cli; pcov replaces xdebug as the coverage driver
# (lighter, no "zend_mm_heap corrupted" crashes with pest --type-coverage).
# sqlite3 for in-memory test databases. No sqlsrv — tests use SQLite.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        software-properties-common ca-certificates curl gnupg git unzip \
    && add-apt-repository -y ppa:ondrej/php \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        php${PHP_VERSION}-cli php${PHP_VERSION}-mbstring php${PHP_VERSION}-xml \
        php${PHP_VERSION}-curl php${PHP_VERSION}-zip php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-intl php${PHP_VERSION}-gd php${PHP_VERSION}-sqlite3 \
        php${PHP_VERSION}-pcov sqlite3 \
    && update-alternatives --set php /usr/bin/php${PHP_VERSION} \
    && rm -rf /var/lib/apt/lists/* \
    && php -v \
    && php -m | grep -qx sockets \
    && php -m | grep -qx pcov \
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

LABEL org.opencontainers.image.title="laravolt-ci" \
      org.opencontainers.image.description="CI image for Laravolt projects: PHP ${PHP_VERSION} (pcov), Composer ${COMPOSER_VERSION}, Node.js ${NODE_MAJOR}.x, Bun ${BUN_VERSION}, Playwright ${PLAYWRIGHT_VERSION} Chromium"
