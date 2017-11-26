#!/bin/bash

: ${MW_SITE_NAME:=MediaWiki}
: ${MW_SITE_SERVER:="http://localhost"}
: ${MW_SITE_LANG:=en}
: ${MW_ADMIN_USER:=admin}
: ${MW_ADMIN_PASS:=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)}
: ${MW_PRIVATE:=true}
: ${MW_ENABLE_UPLOADS:=true}

: ${DB_TYPE:=mysql}
: ${DB_HOST:=mysql}
: ${DB_USER:=root}
: ${DB_PORT:=3306}
: ${DB_NAME:=mediawiki}
: ${DB_SCHEMA:=mediawiki}

# Configure php max upload filesize
sed -i 's/upload_max_filesize.*/upload_max_filesize = 20M/g' /etc/php/7.0/fpm/php.ini
sed -i 's/post_max_size.*/post_max_size = 20M/g' /etc/php/7.0/fpm/php.ini

# Change owner so that nginx can write files
chown -R www-data:www-data /usr/src/mediawiki/

# Validate
if [ -z "${DB_PASSWORD}" ]; then
    echo >&2 "DB_PASSWORD is missing, exiting installation"
    exit 1
fi

# Wait for the DB to come up
while [ `/bin/nc ${DB_HOST} ${DB_PORT} < /dev/null > /dev/null; echo $?` != 0 ]; do
    echo "Waiting for database to come up at ${DB_HOST}:${DB_PORT}..."
    sleep 3
done

# If there isn't a LocalSettings.php file we run the installation script
if [ ! -f "/var/www/html/LocalSettings.php" ]; then
    echo "Installing ..."
    # DB_SCHEMA is only for postgres/sqlserver
    php /var/www/html/maintenance/install.php \
        --server "${MW_SITE_SERVER}" \
        --dbuser "${DB_USER}" \
        --dbpass "${DB_PASSWORD}" \
        --confpath /var/www/html \
        --dbname "${DB_NAME}" \
        --dbport "${DB_PORT}" \
        --dbschema "${DB_SCHEMA}" \
        --dbserver "${DB_HOST}" \
        --dbtype "${DB_TYPE}" \
        --installdbpass "${DB_PASSWORD}" \
        --installdbuser "${DB_USER}" \
        --pass "${MW_ADMIN_PASS}" \
        --scriptpath "" \
        "${MW_SITE_NAME}" \
        "${MW_ADMIN_USER}"

    # Set wiki language
    sed -i -e "s/\$wgLanguageCode.*/\$wgLanguageCode = \"${MW_SITE_LANG}\";/g" /var/www/html/LocalSettings.php

    # Enable uploads
    if [ ${MW_ENABLE_UPLOADS} = true ]; then
        sed -i -e "s/\$wgEnableUploads.*/\$wgEnableUploads = true;/g" /var/www/html/LocalSettings.php
    fi

    # Set wiki as private
    if [ ${MW_PRIVATE} = true ]; then
		cat <<- 'EOLOCALSETTINGS' >> /var/www/html/LocalSettings.php
		# Disable reading by anonymous users
		$wgGroupPermissions['*']['read'] = false;

		# Allow access to the login page
		$wgWhitelistRead = array ("Special:Userlogin");

		# Disable anonymous editing
		$wgGroupPermissions['*']['edit'] = false;

		# Prevent new user registrations except by sysops
		$wgGroupPermissions['*']['createaccount'] = false;

		EOLOCALSETTINGS
    fi

    # Set contact email
    if [ ! -z "${MW_EMAIL}" ]; then
        sed -i -e "s/\$wgEmergencyContact.*/\$wgEmergencyContact = \"${MW_EMAIL}\";/g" /var/www/html/LocalSettings.php
        sed -i -e "s/\$wgPasswordSender.*/\$wgPasswordSender = \"${MW_EMAIL}\";/g" /var/www/html/LocalSettings.php
    fi

    # Set SMTP
    if [ ! -z "${MW_SMTP_HOST}" ]; then
		cat <<- EOLOCALSETTINGS >> /var/www/html/LocalSettings.php
		\$wgSMTP = array(
			'host' => '${MW_SMTP_HOST}',
			'IDHost' => '${MW_SMTP_IDHOST}',
			'port' => ${MW_SMTP_PORT},
			'username' => '${MW_SMTP_USERNAME}',
			'password' => '${MW_SMTP_PASSWORD}',
			'auth' => ${MW_SMTP_AUTH}
		);

		EOLOCALSETTINGS
    fi

    echo "Installation complete"
    echo "Admin password is: ${MW_ADMIN_PASS}"
fi
