FROM php:8.5-cli-bookworm

# Non-interactive apt.
ENV DEBIAN_FRONTEND=noninteractive

# System deps required to build the PHP extensions we actually use.
# Keep this list intentionally minimal — new deps require a task justification.
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        unzip \
        libpq-dev \
        libzip-dev \
        libicu-dev \
        libonig-dev \
    && docker-php-ext-install -j"$(nproc)" \
        pdo_pgsql \
        pgsql \
        intl \
        zip \
        bcmath \
    && rm -rf /var/lib/apt/lists/*

# Composer 2 from the official image.
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_NO_INTERACTION=1 \
    COMPOSER_MEMORY_LIMIT=-1

WORKDIR /var/www/html

# Copy composer manifests first so dependency installs cache when
# only application code changes. This is a development image, so we
# intentionally include require-dev (PHPUnit, Pint, etc.).
COPY composer.json composer.lock ./
RUN composer install --no-progress --no-scripts --no-autoloader --prefer-dist

# Copy the rest of the application.
COPY . .

RUN composer dump-autoload --optimize \
    && mkdir -p storage/framework/cache/data \
                storage/framework/sessions \
                storage/framework/views \
                storage/framework/testing \
                storage/logs \
                bootstrap/cache \
    && chmod -R ug+rwX storage bootstrap/cache

COPY docker/php/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
