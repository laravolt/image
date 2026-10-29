ARG PHP_VERSION='8.5'
ARG BASE_VARIATION='frankenphp-debian'
ARG SERVERSIDEUP_VERSION='v4.5.1'
ARG BASE_IMAGE="serversideup/php:${PHP_VERSION}-${BASE_VARIATION}-${SERVERSIDEUP_VERSION}"

FROM ${BASE_IMAGE}

# Switch to root so we can install deployment dependencies/extensions.
USER root

# The install-php-extensions bundled with the base image picks msodbcsql17 on
# Debian 13 (trixie), which is not installable there. Install msodbcsql18 first;
# install-php-extensions skips its own ODBC step when /opt/microsoft/msodbcsql*/ exists.
RUN . /etc/os-release && \
    if [ "$ID" = "debian" ]; then \
        apt-get update && \
        apt-get install -y --no-install-recommends ca-certificates curl gnupg && \
        curl -fsSL https://packages.microsoft.com/keys/microsoft-2025.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg && \
        curl -fsSL "https://packages.microsoft.com/config/debian/${VERSION_ID}/prod.list" -o /etc/apt/sources.list.d/mssql-release.list && \
        apt-get update && \
        ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 unixodbc-dev; \
    fi

# ServerSideUp PHP images already include common Laravel deployment extensions
# such as zip, PDO database drivers, and Redis. Install only Laravolt-specific
# extensions that are not guaranteed by the upstream image.
RUN install-php-extensions \
    bcmath \
    exif \
    gd \
    intl \
    pdo_sqlsrv \
    sqlsrv

COPY 40-laravolt-link.sh /etc/entrypoint.d/

# Copy shell aliases to both root and www-data user homes.
COPY shell/aliases.sh /root/.aliases.sh
COPY shell/bashrc /root/.bashrc
COPY shell/aliases.sh /var/www/.aliases.sh
COPY shell/bashrc /var/www/.bashrc

# Clean up temporary files produced by extension installation.
RUN rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/lib/apt/lists/*

# Drop back to the ServerSideUp unprivileged user.
USER www-data

RUN composer global config allow-plugins.gmta/composer-velocita true && \
    composer global require gmta/composer-velocita
