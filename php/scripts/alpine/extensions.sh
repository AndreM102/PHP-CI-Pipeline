#!/bin/bash

set -euf -o pipefail

apk --update --no-cache add \
  bzip2 \
  bzip2-dev \
  curl-dev \
  cyrus-sasl-dev \
  freetype-dev \
  gmp-dev \
  icu-dev \
  imagemagick \
  imagemagick-dev \
  imap-dev \
  krb5-dev \
  libbz2 \
  libedit-dev \
  libintl \
  libjpeg-turbo-dev \
  libltdl \
  libmemcached-dev \
  libpng-dev \
  libtool \
  libxml2-dev \
  libxslt-dev \
  openldap-dev \
  pcre-dev \
  postgresql-dev \
  readline-dev \
  sqlite-dev \
  zlib-dev

docker-php-ext-configure ldap
docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) ldap
docker-php-ext-configure imap --with-kerberos --with-imap-ssl
docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) imap
docker-php-ext-configure gd \
        --with-gd \
        --with-freetype-dir=/usr/include \
        --with-jpeg-dir=/usr/include \
        --with-png-dir=/usr/include
docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) gd
docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) exif xml xmlrpc pcntl bcmath bz2 calendar iconv intl mbstring mysqli opcache pdo_mysql pdo_pgsql pgsql soap zip
docker-php-source delete

# pecl install pdo_sqlsrv sqlsrv \
#   && docker-php-ext-enable pdo_sqlsrv sqlsrv

if [[ $PHP_VERSION == "7.3" ]]; then
  apk --update --no-cache add libzip-dev
  git clone --depth 1 -b 2.7.0beta1 "https://github.com/xdebug/xdebug" \
    && cd xdebug \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && docker-php-ext-enable xdebug
elif [[ $PHP_VERSION == "7.2" ]]; then
  git clone --depth 1 "https://github.com/xdebug/xdebug" \
    && cd xdebug \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && docker-php-ext-enable xdebug
else
  apk --update --no-cache add \
    libmcrypt-dev \
    libmcrypt \

    docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) mcrypt

    pecl install xdebug \
      && docker-php-ext-enable xdebug
fi

docker-php-source extract \
    && curl -L -o /tmp/redis.tar.gz "https://github.com/phpredis/phpredis/archive/4.2.0.tar.gz" \
    && tar xfz /tmp/redis.tar.gz \
    && rm -r /tmp/redis.tar.gz \
    && mv phpredis-4.2.0 /usr/src/php/ext/redis \
    && docker-php-ext-install redis \
    && docker-php-source delete

docker-php-source extract \
    && apk add --no-cache --virtual .phpize-deps-configure $PHPIZE_DEPS \
    && pecl install apcu \
    && docker-php-ext-enable apcu \
    && apk del .phpize-deps-configure \
    && docker-php-source delete

pecl install imagick \
    && docker-php-ext-enable imagick

pecl install mongodb \
    && docker-php-ext-enable mongodb

git clone "https://github.com/php-memcached-dev/php-memcached.git" \
    && cd php-memcached \
    && phpize \
    && ./configure --disable-memcached-sasl \
    && make \
    && make install \
    && cd ../ && rm -rf php-memcached \
    && docker-php-ext-enable memcached

{ \
    echo 'opcache.enable=1'; \
    echo 'opcache.revalidate_freq=0'; \
    echo 'opcache.validate_timestamps=1'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.memory_consumption=192'; \
    echo 'opcache.max_wasted_percentage=10'; \
    echo 'opcache.interned_strings_buffer=16'; \
    echo 'opcache.fast_shutdown=1'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini

{ \
    echo 'apc.shm_segments=1'; \
    echo 'apc.shm_size=512M'; \
    echo 'apc.num_files_hint=7000'; \
    echo 'apc.user_entries_hint=4096'; \
    echo 'apc.ttl=7200'; \
    echo 'apc.user_ttl=7200'; \
    echo 'apc.gc_ttl=3600'; \
    echo 'apc.max_file_size=50M'; \
    echo 'apc.stat=1'; \
} > /usr/local/etc/php/conf.d/apcu-recommended.ini

echo "memory_limit=512M" > /usr/local/etc/php/conf.d/zz-conf.ini
