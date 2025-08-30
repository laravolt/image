############################################
# Base Image
############################################
FROM serversideup/php-dev:283-8.3-frankenphp

# Switch to root so we can do root things
USER root

RUN install-php-extensions bcmath exif gd

# Copy shell aliases to both root and www-data user homes
COPY shell/aliases.sh /root/.aliases.sh
COPY shell/bashrc /root/.bashrc

# Drop back to our unprivileged user
USER www-data

RUN composer global config allow-plugins.gmta/composer-velocita true && \
    composer global require gmta/composer-velocita

# Copy shell configuration
COPY shell/aliases.sh /var/www/.aliases.sh
COPY shell/bashrc /var/www/.bashrc
