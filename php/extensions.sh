#!/bin/bash

apt-get update && apt-get install -y \
    libmcrypt-dev \
    libxml2-dev \
    libcurl4-gnutls-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng12-dev \
    libssl-dev \
    libicu-dev \
    libbz2-dev \
    libc-client-dev \
    libkrb5-dev \
    zlib1g-dev \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) \
        gd \
        curl \
        mcrypt \
        json \
        xml \
        mbstring \
        pdo \
        pdo_mysql \
        iconv \
        opcache \
        intl \
        zip \
        bz2 \
        bcmath \
        tokenizer

# MONGO extension
pecl install mongodb \
  && docker-php-ext-enable mongodb
#&& echo "extension=mongodb.so" > /usr/local/etc/php/conf.d/mongo.ini

# Run xdebug installation.
# /usr/local/lib/php/extensions/no-debug-non-zts-20160303/xdebug.so
pecl install xdebug-2.5.0 \
  && docker-php-ext-enable xdebug
