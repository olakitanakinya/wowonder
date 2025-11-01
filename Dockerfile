FROM php:8.2-fpm

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
    nginx \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql mysqli mbstring exif pcntl bcmath gd zip

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy nginx configuration
COPY nginx.conf /etc/nginx/sites-available/default

# Copy PHP configuration
COPY php.ini /usr/local/etc/php/conf.d/custom.ini

# Copy supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . .

# Create necessary directories and set permissions
RUN mkdir -p /var/www/html/upload /var/www/html/cache /var/www/html/admin-panel \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/upload \
    && chmod -R 755 /var/www/html/cache \
    && chmod -R 755 /var/www/html/admin-panel

# Create log directory
RUN mkdir -p /var/log/php && chown www-data:www-data /var/log/php

# Test nginx configuration
RUN nginx -t

# Expose port 80
EXPOSE 80

# Start supervisor to manage processes
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
