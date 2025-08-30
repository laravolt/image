ARG PHP_VERSION='8.4'
ARG BASE_IMAGE="serversideup/php-dev:283-${PHP_VERSION}-frankenphp"

FROM ${BASE_IMAGE}

# Switch to root so we can do root things
USER root

RUN apt update && \
    apt install -y git && \
    install-php-extensions bcmath exif gd

COPY 40-laravolt-link.sh /etc/entrypoint.d/

# Copy shell aliases to both root and www-data user homes
COPY shell/aliases.sh /root/.aliases.sh
COPY shell/bashrc /root/.bashrc

# Clean up
RUN rm -rf /var/cache/apk/* && \
    rm -rf /tmp/* /var/tmp/*

# Drop back to our unprivileged user
USER www-data

RUN composer global config allow-plugins.gmta/composer-velocita true && \
    composer global require gmta/composer-velocita

# Copy shell configuration
COPY shell/aliases.sh /var/www/.aliases.sh
COPY shell/bashrc /var/www/.bashrc
