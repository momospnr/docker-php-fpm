FROM php:7.3.11-fpm-alpine3.10 AS build-env

LABEL maintainer="momospnr"

ENV APP_DEPS \
  autoconf \
  curl \
  make \
  tar \
  libmcrypt \
  libpng \
  libjpeg-turbo \
  libxml2 \
  libedit \
  libxslt \
  libzip \
  icu \
  freetype \
  jpeg \
  gettext \
  redis \
  nodejs \
  yarn \
  git \
  unzip \
  openssl \
  bash

ENV PHP_EXT \
  json \
  exif \
  xml \
  pdo \
  mbstring \
  mysqli \
  pdo_mysql \
  redis \
  opcache \
  calendar \
  ctype \
  dom \
  fileinfo \
  ftp \
  intl \
  iconv \
  phar \
  posix \
  readline \
  shmop \
  simplexml \
  soap \
  sockets \
  sysvmsg \
  sysvsem \
  sysvshm \
  tokenizer \
  wddx \
  xmlwriter \
  xmlrpc

ENV PECL_EXT \
  xdebug \
  apcu \
  igbinary \
  msgpack \
  mcrypt \
  zip 

ENV BUILD_DEPS \
  build-base \
  freetype-dev \
  libjpeg-turbo-dev \
  libpng-dev \
  gettext-dev \
  mysql-dev \
  pcre-dev \
  libc-dev \
  jpeg-dev \
  libpng-dev \
  libxml2-dev \
  libedit-dev \
  libxslt-dev \
  libmcrypt-dev \
  libzip-dev \
  icu-dev \
  tzdata \
  ruby-dev \
  sqlite-dev

ENV DOCKERIZE_VERSION v0.6.1

# Package Install
RUN set -ex \
  && apk update \
  && apk add --no-cache \
  ${APP_DEPS} \
  ${BUILD_DEPS} \
  && cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
  && pecl install \
  ${PECL_EXT} \
  && docker-php-source extract \
  && git clone -b 5.1.1 --depth 1 https://github.com/phpredis/phpredis.git /usr/src/php/ext/redis \
  && docker-php-ext-install \
  ${PHP_EXT} \
  && CFLAGS="-I/usr/src/php" docker-php-ext-install xmlreader \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install -j$(nproc) gd \
  && docker-php-ext-enable \
  ${PECL_EXT} \
  && wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
  && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
  && rm dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
  && cd ~ \
  && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin \
  && mv /usr/local/bin/composer.phar /usr/local/bin/composer \
  && apk del --purge ${BUILD_DEPS}

FROM php:7.3.11-fpm-alpine3.10 AS dev

LABEL maintainer="momospnr"

ENV APP_DEPS \
  autoconf \
  curl \
  make \
  tar \
  libmcrypt \
  libpng \
  libjpeg-turbo \
  libxml2 \
  libedit \
  libxslt \
  libzip \
  icu \
  freetype \
  jpeg \
  gettext \
  ruby \
  ruby-rdoc \
  sqlite \
  redis \
  nodejs \
  yarn \
  git \
  unzip \
  openssl \
  bash

ENV BUILD_DEPS \
  build-base \
  ruby-dev \
  sqlite-dev

RUN set -ex \
  && apk update \
  && apk add --no-cache \
  ${APP_DEPS} \
  ${BUILD_DEPS} \
  && gem install mailcatcher etc \
  && rm -rf /usr/local/lib/php/extensions/no-debug-non-zts-20180731 \
  && apk del --purge ${BUILD_DEPS}

COPY --from=build-env /usr/local/lib/php/extensions/no-debug-non-zts-20180731 /usr/local/lib/php/extensions/no-debug-non-zts-20180731
COPY --from=build-env /usr/local/etc/php/conf.d/* /usr/local/etc/php/conf.d/
COPY --from=build-env /usr/local/bin/composer /usr/local/bin/composer
COPY --from=build-env /usr/local/bin/dockerize /usr/local/bin/dockerize
COPY --from=build-env /etc/localtime /etc/localtime
COPY www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php.ini-development /usr/local/etc/php/php.ini

EXPOSE 9000
CMD ["/usr/local/sbin/php-fpm", "-F"]

FROM php:7.3.11-fpm-alpine3.10 AS prd

LABEL maintainer="momospnr"

ENV APP_DEPS \
  autoconf \
  curl \
  make \
  tar \
  libmcrypt \
  libpng \
  libjpeg-turbo \
  libxml2 \
  libedit \
  libxslt \
  libzip \
  icu \
  freetype \
  jpeg \
  gettext \
  ruby \
  ruby-rdoc \
  sqlite \
  redis \
  nodejs \
  yarn \
  git \
  unzip \
  openssl \
  bash

RUN set -ex \
  && apk update \
  && apk add --no-cache \
  ${APP_DEPS} \
  && rm -rf /usr/local/lib/php/extensions/no-debug-non-zts-20180731

COPY --from=build-env /usr/local/lib/php/extensions/no-debug-non-zts-20180731 /usr/local/lib/php/extensions/no-debug-non-zts-20180731
COPY --from=build-env /usr/local/etc/php/conf.d/* /usr/local/etc/php/conf.d/
COPY --from=build-env /usr/local/bin/composer /usr/local/bin/composer
COPY --from=build-env /etc/localtime /etc/localtime
COPY www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php.ini-production /usr/local/etc/php/php.ini

EXPOSE 9000
CMD ["/usr/local/sbin/php-fpm", "-F"]