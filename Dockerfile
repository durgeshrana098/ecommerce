# Use PHP 8.2 with Apache
FROM php:8.2-apache

# Set working directory
WORKDIR /var/www/html

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
    nodejs \
    npm \
    libicu-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libgd-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    pdo_pgsql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    intl \
    calendar

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Configure Apache
RUN echo '<VirtualHost *:80>\n\
    DocumentRoot /var/www/html/public\n\
    <Directory /var/www/html/public>\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
    ErrorLog ${APACHE_LOG_DIR}/error.log\n\
    CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Copy application files
COPY . /var/www/html

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Install Node.js dependencies and build assets
RUN if [ -f "package-lock.json" ]; then \
        npm ci; \
    else \
        npm install; \
    fi \
    && npm run build \
    && rm -rf node_modules

# Create storage directories if they don't exist
RUN mkdir -p /var/www/html/storage/logs \
    && mkdir -p /var/www/html/storage/framework/cache \
    && mkdir -p /var/www/html/storage/framework/sessions \
    && mkdir -p /var/www/html/storage/framework/views \
    && mkdir -p /var/www/html/storage/app/public

# Set proper permissions again after creating directories
RUN chown -R www-data:www-data /var/www/html/storage \
    && chown -R www-data:www-data /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache

# Create entrypoint script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Fix permissions at runtime\n\
echo "Setting up permissions..."\n\
chown -R www-data:www-data /var/www/html/storage\n\
chown -R www-data:www-data /var/www/html/bootstrap/cache\n\
chmod -R 775 /var/www/html/storage\n\
chmod -R 775 /var/www/html/bootstrap/cache\n\
\n\
# Generate APP_KEY if not set\n\
if [ -z "$APP_KEY" ]; then\n\
    echo "Generating APP_KEY..."\n\
    php artisan key:generate --force\n\
fi\n\
\n\
# Start Apache in background\n\
apache2-foreground &\n\
APACHE_PID=$!\n\
\n\
# Wait a bit for Apache to start\n\
sleep 3\n\
\n\
# Try database operations in background\n\
{\n\
    echo "Checking database connection..."\n\
    # Wait for database with timeout\n\
    timeout=60\n\
    counter=0\n\
    until php artisan migrate:status > /dev/null 2>&1 || [ $counter -eq $timeout ]; do\n\
        echo "Database not ready, waiting... ($counter/$timeout)"\n\
        sleep 5\n\
        counter=$((counter + 5))\n\
    done\n\
    \n\
    if [ $counter -lt $timeout ]; then\n\
        echo "Database connected! Running setup..."\n\
        php artisan migrate --force\n\
        php artisan config:cache\n\
        php artisan route:cache\n\
        php artisan view:cache\n\
        php artisan storage:link\n\
        echo "Database setup complete!"\n\
    else\n\
        echo "Database connection timeout. App will run in installer mode."\n\
        # Clear config cache to allow installer\n\
        php artisan config:clear\n\
    fi\n\
} &\n\
\n\
# Wait for Apache process\n\
wait $APACHE_PID' > /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
