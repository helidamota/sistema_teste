#unica tag obrigatória deve colocar a imagem base
FROM php:8.3-apache-bullseye
#defini o diretorio onde serão executados os comando RUN
WORKDIR /var/www/html
#executa no momento de criação da imagem

RUN pecl install xdebug
RUN docker-php-ext-enable xdebug

RUN apt-get update && apt-get install -y \
    curl \
    libpq-dev \
    zip \
    unzip \
    openssl \
    libzip-dev \
    nodejs \
    npm \
    && docker-php-ext-configure zip \
    && docker-php-ext-install zip pdo pdo_pgsql pgsql

RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libxpm-dev \
    zlib1g-dev && \
    docker-php-ext-configure gd --enable-gd --with-webp --with-jpeg \
    --with-xpm --with-freetype && \
    docker-php-ext-install -j$(nproc) gd && \
    rm -rf /var/lib/apt/lists/*

# redis
RUN pecl install redis && docker-php-ext-enable redis

# install composer
#COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer
# Install Composer
#RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /var/www/html

#copia os arquivos do diretorio atual para o diretorio /var/www/html do container
COPY . /var/www/html

RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache

# Node.js, NPM, Yarn
RUN curl -sL https://deb.nodesource.com/setup_22.x | bash -
RUN apt-get install -y nodejs
RUN npm install npm@latest -g
RUN npm install yarn -g

# Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer

# install php and node.js dependencies
#RUN composer install --no-dev --prefer-dist \
#    && npm install \
#    && npm run build

RUN chown -R www-data:www-data /var/www/html/vendor \
    && chmod -R 775 /var/www/html/vendor

RUN a2enmod rewrite && service apache2 restart \
    && chmod 777 /var/www/html/apache/log -R

#expõe uma porta
EXPOSE 80
