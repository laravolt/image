ARG PHP_VERSION='8.5'
ARG BASE_VARIATION='frankenphp-debian'
ARG SERVERSIDEUP_VERSION='v4.4.0'
ARG BASE_IMAGE="serversideup/php:${PHP_VERSION}-${BASE_VARIATION}-${SERVERSIDEUP_VERSION}"

FROM ${BASE_IMAGE}

# Switch to root so we can install deployment dependencies/extensions.
USER root

# ServerSideUp PHP images already include common Laravel deployment extensions
# such as zip, PDO database drivers, and Redis. Install only Laravolt-specific
# extensions that are not guaranteed by the upstream image.
RUN install-php-extensions \
    bcmath \
    exif \
    gd \
    intl

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
