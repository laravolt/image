# Development image for Laravolt projects: the runtime image plus the
# tools a laptop needs, so a team can `docker compose pull` instead of
# building locally. Published as laravoltdev/image:php<version>-dev.
#
# Mount the project on /var/www/html. Vite runs inside the container with Bun.

ARG BASE_IMAGE=laravoltdev/image:php8.5-frankenphp-debian
FROM ${BASE_IMAGE}

ARG BUN_VERSION=1.4.3

USER root

# Bun for `bun install` / `bun run dev`, installed system-wide so www-data can run it.
RUN curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash -s "bun-v${BUN_VERSION}" \
    && bun --version

# Xdebug, off by default. Turn it on per container with XDEBUG_MODE=debug (or coverage).
RUN install-php-extensions xdebug \
    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*
# AUTORUN_LARAVEL_SKIP_IF_NOT_FOUND (ServerSideUp v5) keeps the container running
# when it starts before a Laravel project is mounted or installed.
ENV XDEBUG_MODE=off \
    AUTORUN_ENABLED=true \
    AUTORUN_LARAVEL_SKIP_IF_NOT_FOUND=true \
    AUTORUN_LARAVOLT_LINK=true

EXPOSE 5173

USER www-data

LABEL org.opencontainers.image.title="laravolt-dev" \
      org.opencontainers.image.description="Laravolt development image: ServerSideUp PHP + FrankenPHP + Laravolt extensions, Bun ${BUN_VERSION}, Xdebug (off by default)"
