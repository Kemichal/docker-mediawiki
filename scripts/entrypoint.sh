#!/bin/bash

# Mount upper over mediawiki in the www folder
# Upper and workdir must be on the same filesystem
# If this wasn't required we would've put workdir in the container instead of in the volume
mkdir -p /data/{upper,work}
mount -t overlay -o \
    lowerdir=/usr/src/mediawiki/,upperdir=/data/upper,workdir=/data/work \
    overlay /var/www/html

/scripts/install.sh

php /var/www/html/maintenance/update.php --quick

# Run the command (default supervisord)
exec "$@"
