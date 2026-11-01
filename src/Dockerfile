ARG PHP_VERSION='8.5'
ARG BASE_VARIATION='frankenphp-debian'
# ServerSideUp release. The update-base-image workflow bumps it; the build workflows read it from here.
ARG SERVERSIDEUP_VERSION='v5.0.5'
ARG BASE_IMAGE="serversideup/php:${PHP_VERSION}-${BASE_VARIATION}-${SERVERSIDEUP_VERSION}"

FROM ${BASE_IMAGE}

# Switch to root so we can install deployment dependencies/extensions.
USER root

# The install-php-extensions bundled with the base image picks msodbcsql17 on
# Debian 13 (trixie), which is not installable there. Install msodbcsql18 first;
# install-php-extensions skips its own ODBC step when /opt/microsoft/msodbcsql*/ exists.
#
# Also apply pending Debian security updates, so a rebuild picks up fixes
# (for example libbrotli, CVE-2026-111497) before the base image is rebuilt.
RUN . /etc/os-release && \
    if [ "$ID" = "debian" ]; then \
        apt-get update && \
        apt-get upgrade -y --no-install-recommends && \
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

COPY --chmod=755 40-laravolt-link.sh /etc/entrypoint.d/

# Turn off session upload progress until PHP fixes CVE-2026-115560. ServerSideUp
# v5.0.3+ does the same; this keeps it off whatever the base image sets.
COPY --chmod=644 php/zz-laravolt-security.ini "${PHP_INI_DIR}/conf.d/"

# Copy shell aliases to both root and www-data user homes.
COPY --chmod=644 shell/aliases.sh /root/.aliases.sh
COPY --chmod=644 shell/bashrc /root/.bashrc
COPY --chmod=644 shell/aliases.sh /var/www/.aliases.sh
COPY --chmod=644 shell/bashrc /var/www/.bashrc

# Clean up temporary files produced by extension installation.
RUN rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/lib/apt/lists/*

# ServerSideUp v4.3.1 to v5.0.4 shipped world-writable files under /etc/frankenphp,
# so any user in the container could change the Caddyfile (GHSA-xx74-jh2r-mgm3).
# v5.0.5 fixes that upstream; this keeps our own layers to the same rule. Remove
# write access for others everywhere except sticky directories such as /tmp.
RUN find / -xdev -perm -0002 \( -type d ! -perm -1000 -o -type f \) -exec chmod o-w {} +

# Drop back to the ServerSideUp unprivileged user.
USER www-data

RUN composer global config allow-plugins.gmta/composer-velocita true && \
    composer global require gmta/composer-velocita
