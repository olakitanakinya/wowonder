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

# Install PHP extensions including MySQLi
RUN docker-php-ext-install pdo pdo_mysql mysqli mbstring exif pcntl bcmath gd zip

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create nginx configuration directory and copy config
RUN mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
COPY nginx.conf /etc/nginx/sites-available/default
RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Copy PHP configuration
COPY php.ini /usr/local/etc/php/conf.d/custom.ini

# Create supervisor directory and copy config
RUN mkdir -p /etc/supervisor/conf.d
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create necessary directories
RUN mkdir -p /var/log/supervisor /var/log/php

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . .

# Install composer dependencies (if composer.json exists)
RUN if [ -f "composer.json" ]; then composer install --no-dev --optimize-autoloader; fi

# Create necessary directories and set permissions
RUN mkdir -p /var/www/html/upload /var/www/html/cache /var/www/html/admin-panel \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/upload \
    && chmod -R 755 /var/www/html/cache \
    && chmod -R 755 /var/www/html/admin-panel

# Check if config.php exists and set permissions if it does
RUN if [ -f /var/www/html/config.php ]; then chmod 644 /var/www/html/config.php; fi

# Verify PHP extensions are installed
RUN echo "=== Checking PHP Extensions ===" && \
    php -m | grep -i mysqli && echo "✓ MySQLi enabled" || echo "✗ MySQLi NOT enabled" && \
    php -m | grep -i pdo_mysql && echo "✓ PDO MySQL enabled" || echo "✗ PDO MySQL NOT enabled" && \
    php -m | grep -i mbstring && echo "✓ MBString enabled" || echo "✗ MBString NOT enabled" && \
    php -m | grep -i gd && echo "✓ GD enabled" || echo "✗ GD NOT enabled"

# Test nginx configuration
RUN nginx -t

# Expose port 80
EXPOSE 80

# Start supervisor to manage processes
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
