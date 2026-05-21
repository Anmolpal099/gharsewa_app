FROM php:8.2-fpm

# Set working directory
WORKDIR /var/www

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Step 1: Create fresh Laravel project
RUN composer create-project laravel/laravel . --prefer-dist --no-interaction

# Step 2: Install additional packages
RUN composer require \
    kreait/laravel-firebase:^5.0 \
    beyondcode/laravel-websockets:^1.14 \
    predis/predis:^2.2 \
    spatie/laravel-permission:^6.0 \
    stripe/stripe-php:^13.0 \
    --no-interaction

# Step 3: Copy our custom files (overwrite Laravel defaults)
COPY app/ app/
COPY database/ database/
COPY routes/ routes/
COPY config/ config/
COPY bootstrap/ bootstrap/
COPY storage/ storage/

# Step 4: Set permissions
RUN chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage \
    && chmod -R 755 /var/www/bootstrap/cache

EXPOSE 9000

CMD ["php-fpm"]
