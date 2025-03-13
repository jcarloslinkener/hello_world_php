FROM php:7.0-fpm

WORKDIR /code

#add by markitos - repositorios antiguos ya no existen y
#toca poner estos para que funcione
RUN sed -i -e 's/deb.debian.org/archive.debian.org/g' \
           -e 's|security.debian.org|archive.debian.org/|g' \
           -e '/stretch-updates/d' /etc/apt/sources.list

ENV SYMFONY_ENV dev
ENV SYMFONY_DEBUG 1

# install core packages and supervisor
RUN apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
        procps \
        moreutils \
        htop \
        unzip \
        git \
        vim \
        gettext \
        supervisor \
        sudo

# wkhtmltopdf
COPY ./docker/enerlin/wkhtmltox-stretch-0.12.5.deb /tmp/wkhtmltox-stretch-0.12.5.deb
RUN apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
        ca-certificates \
        fontconfig \
        libfreetype6 \
        libjpeg62-turbo \
        libx11-6 \
        libxcb1 \
        libxext6 \
        libxrender1 \
        xfonts-75dpi \
        xfonts-base && \
    dpkg -i /tmp/wkhtmltox-stretch-0.12.5.deb

# php extensions
RUN apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
        mysql-client \
        zlib1g-dev \
        libicu-dev \
        libmcrypt-dev \
        libpng-dev \
        libmagickwand-dev && \
    docker-php-ext-install -j$(nproc) \
        bcmath \
        pdo_mysql \
        intl \
        mcrypt \
        zip \
        gd \
        exif \
        sockets \
        pcntl && \
    pecl install xdebug-2.6.0 && \
    pecl install apcu-5.1.12 && \
    pecl install imagick && \
    docker-php-ext-enable imagick && \
    docker-php-ext-enable xdebug apcu

# Copy newer version of CA certs (avoid expired CA certs https://linkener.atlassian.net/browse/LIN-3090)
COPY ./docker/enerlin/ssl-certs.tar.gz /tmp
RUN rm -r /etc/ssl/ && tar xzvf /tmp/ssl-certs.tar.gz -C /etc && \
    rm /tmp/ssl-certs.tar.gz

# composer
ENV COMPOSER_HOME /code/app/cache/composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    rm composer-setup.php && \
    chmod +x composer.phar && \
    mv composer.phar /usr/local/bin/composer && \
    composer self-update 1.10.16

# default php config
COPY ./docker/enerlin/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY ./docker/enerlin/php.ini /usr/local/etc/php/php.ini

# remove all other config (except /usr/local/etc/php/conf.d for the extensions)
RUN rm /usr/local/etc/php-fpm.conf.default && \
    rm -r /usr/local/etc/php-fpm.d

# create user of FPM worker
RUN useradd -r -M -G www-data,sudo -u 1000 php-user
RUN echo "php-user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER php-user

ENTRYPOINT ["/bin/bash", "/code/docker/enerlin/cmd.sh"]
