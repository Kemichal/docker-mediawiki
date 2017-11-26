FROM ubuntu:16.04
LABEL maintainer = "Robert Andersson <kemichal@gmail.com>"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    imagemagick \
    nginx \
    netcat \
    php-fpm \
    php-cli \
    php-curl \
    php-gd \
    php-mysql \
    php-mbstring \
    php-xml \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

ARG MEDIAWIKI_VERSION

RUN MEDIAWIKI_MINOR=$(echo $MEDIAWIKI_VERSION | sed -e 's/\.[0-9]\+$//g') \
    && mkdir -p /usr/src/mediawiki \
    && curl -O https://releases.wikimedia.org/mediawiki/$MEDIAWIKI_MINOR/mediawiki-$MEDIAWIKI_VERSION.tar.gz \
    && tar xfz mediawiki-$MEDIAWIKI_VERSION.tar.gz -C /usr/src/mediawiki --strip-components=1 --no-same-owner \
    && rm mediawiki-$MEDIAWIKI_VERSION.tar.gz \
    && cd /usr/src/mediawiki

EXPOSE 80

VOLUME /data

COPY config/nginx.conf /etc/nginx/sites-available/default

# Supervisors default configs are in /etc/supervisor/conf.d/
COPY config/supervisord.conf /etc/supervisord.conf

# Without this php-fpm fails to run
RUN mkdir /var/run/php

COPY scripts/entrypoint.sh /scripts/entrypoint.sh
COPY scripts/install.sh /scripts/install.sh

RUN chmod -R +x /scripts

ENTRYPOINT ["/scripts/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
