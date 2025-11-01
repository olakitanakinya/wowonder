FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev libzip-dev \
    zip unzip nginx supervisor && apt-get clean

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql mysqli mbstring gd zip

# Copy configurations
COPY nginx.conf /etc/nginx/sites-available/default
COPY php.ini /usr/local/etc/php/conf.d/custom.ini
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set working directory
WORKDIR /var/www/html

# Copy application
COPY . .

# Create directories and set permissions
RUN mkdir -p upload cache admin-panel && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 755 upload

# Expose port
EXPOSE 80

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
