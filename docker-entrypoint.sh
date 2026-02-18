#!/bin/bash

# Exit on error
set -e

echo "Starting ERPNext with fixed configuration..."

# Wait for Redis
echo "Waiting for Redis services..."
while ! redis-cli -h redis-cache -p 6379 ping >/dev/null 2>&1; do
    echo "Waiting for redis-cache..."
    sleep 2
done

while ! redis-cli -h redis-queue -p 6379 ping >/dev/null 2>&1; do
    echo "Waiting for redis-queue..."
    sleep 2
done

echo "Redis services are ready!"

# Wait for Database
echo "Waiting for database at ${DB_HOST:-db}:${DB_PORT:-3306}..."
max_retries=30
counter=0
while ! mysql -h ${DB_HOST:-db} -P ${DB_PORT:-3306} -u ${DB_USER:-ameen_site} -p${DB_PASSWORD:-admin123} -e "SELECT 1" >/dev/null 2>&1; do
    sleep 2
    counter=$((counter+1))
    if [ $counter -ge $max_retries ]; then
        echo "Could not connect to database after $max_retries attempts. Exiting."
        exit 1
    fi
    echo "Waiting for database... ($counter/$max_retries)"
done
echo "Database is ready!"

# Update common_site_config.json for container environment
echo "Updating common_site_config.json..."
cat > /home/frappe/frappe-bench/sites/common_site_config.json << EOF
{
    "redis_cache": "redis://redis-cache:6379",
    "redis_queue": "redis://redis-queue:6379",
    "redis_socketio": "redis://redis-queue:6379",
    "db_host": "${DB_HOST:-db}",
    "db_port": ${DB_PORT:-3306}
}
EOF

# Ensure site exists and is configured
SITE_PATH="/home/frappe/frappe-bench/sites/${SITE_NAME:-erpnext.localhost}"
if [ ! -d "$SITE_PATH" ]; then
    echo "Site directory not found. Creating site..."
    bench new-site ${SITE_NAME:-erpnext.localhost} \
        --db-host ${DB_HOST:-db} \
        --db-port ${DB_PORT:-3306} \
        --db-name ${DB_NAME:-ameen_site} \
        --db-user ${DB_USER:-ameen_site} \
        --db-password ${DB_PASSWORD:-admin123} \
        --admin-password ${ADMIN_PASSWORD:-admin} \
        --no-mariadb-socket
fi

# Check if we need to restore from dump
if [ -f /home/frappe/frappe-bench/dump.sql ] && ! bench --site ${SITE_NAME:-erpnext.localhost} list-apps > /dev/null 2>&1; then
    echo "Restoring from dump file..."
    mysql -h ${DB_HOST:-db} -P ${DB_PORT:-3306} -u ${DB_USER:-ameen_site} -p${DB_PASSWORD:-admin123} ${DB_NAME:-ameen_site} < /home/frappe/frappe-bench/dump.sql
fi

# Always migrate to ensure schema is up to date
echo "Running migrations..."
bench --site ${SITE_NAME:-erpnext.localhost} migrate

# Install custom app if not already installed
if ! bench --site ${SITE_NAME:-erpnext.localhost} list-apps | grep -q "ameen_app"; then
    echo "Installing ameen_app..."
    bench --site ${SITE_NAME:-erpnext.localhost} install-app ameen_app
fi

# Set default site
bench use ${SITE_NAME:-erpnext.localhost}

# Ensure proper permissions
mkdir -p $SITE_PATH/locks
mkdir -p $SITE_PATH/logs

echo "Starting ERPNext..."
exec bench serve --port 8000 --no-reload
