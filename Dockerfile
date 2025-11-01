FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev libzip-dev \
    zip unzip nginx supervisor && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql mysqli mbstring gd zip

# Create nginx directories and remove existing default
RUN mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled && \
    rm -f /etc/nginx/sites-enabled/default

# Copy configurations
COPY nginx.conf /etc/nginx/sites-available/default
RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

COPY php.ini /usr/local/etc/php/conf.d/custom.ini

# Create supervisor directory and copy config
RUN mkdir -p /etc/supervisor/conf.d /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create log directories
RUN mkdir -p /var/log/nginx /var/log/php

# Set working directory
WORKDIR /var/www/html

# Copy application
COPY . .

# Create directories and set permissions
RUN mkdir -p upload cache admin-panel && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 755 upload cache admin-panel

# Test nginx configuration
RUN nginx -t

# Expose port
EXPOSE 80

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
