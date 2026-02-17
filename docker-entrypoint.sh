#!/bin/bash

# Exit on error
# set -e

# Helper to wait for DB
echo "Waiting for database at ${DB_HOST:-db}:${DB_PORT:-3306}..."
max_retries=30
counter=0
while ! mysql -h ${DB_HOST:-db} -P ${DB_PORT:-3306} -u ${DB_NAME:-ameen_site} -p${DB_PASSWORD:-admin123} -e "SELECT 1" >/dev/null 2>&1; do
    sleep 2
    counter=$((counter+1))
    if [ $counter -ge $max_retries ]; then
        echo "Could not connect to database after $max_retries attempts. Exiting."
        exit 1
    fi
    echo "Waiting for database... ($counter/$max_retries)"
done
echo "Database is ready!"

# FIX: Explicitly create/update common_site_config.json for Redis
if [ ! -f /home/frappe/frappe-bench/sites/common_site_config.json ]; then
  echo 'Creating common_site_config.json...'
  echo "{
    \"redis_cache\": \"redis://redis-cache:6379\",
    \"redis_queue\": \"redis://redis-queue:6379\", 
    \"redis_socketio\": \"redis://redis-queue:6379\",
    \"db_host\": \"${DB_HOST:-db}\",
    \"db_port\": ${DB_PORT:-3306}
  }" > /home/frappe/frappe-bench/sites/common_site_config.json
else
   echo 'Updating common_site_config.json...'
   echo "{
    \"redis_cache\": \"redis://redis-cache:6379\",
    \"redis_queue\": \"redis://redis-queue:6379\",
    \"redis_socketio\": \"redis://redis-queue:6379\",
    \"db_host\": \"${DB_HOST:-db}\",
    \"db_port\": ${DB_PORT:-3306}
   }" > /home/frappe/frappe-bench/sites/common_site_config.json
fi

# Ensure locks and logs directories exist
mkdir -p /home/frappe/frappe-bench/sites/${SITE_NAME:-erpnext.localhost}/locks
mkdir -p /home/frappe/frappe-bench/sites/${SITE_NAME:-erpnext.localhost}/logs

if [ ! -f /home/frappe/frappe-bench/sites/${SITE_NAME:-erpnext.localhost}/site_config.json ]; then
  echo 'Creating site config to connect to existing DB...';
  mkdir -p /home/frappe/frappe-bench/sites/${SITE_NAME:-erpnext.localhost}
  
  echo "{
   \"db_name\": \"${DB_NAME:-ameen_site}\",
   \"db_password\": \"${DB_PASSWORD:-admin123}\",
   \"developer_mode\": ${DEVELOPER_MODE:-1},
   \"admin_password\": \"${ADMIN_PASSWORD:-admin}\"
  }" > /home/frappe/frappe-bench/sites/${SITE_NAME:-erpnext.localhost}/site_config.json
fi

# Check if site is installed (has tables)
if ! bench --site ${SITE_NAME:-erpnext.localhost} list-apps > /dev/null 2>&1; then
    echo "Site not ready (tables missing). Attempting setup..."
    
    if [ -f /home/frappe/frappe-bench/dump.sql ]; then
         echo "Dump file found at /home/frappe/frappe-bench/dump.sql. Restoring..."
         # Use mysql directly to avoid bench init issues on empty DB
         mysql -h ${DB_HOST:-db} -P ${DB_PORT:-3306} -u ${DB_NAME:-ameen_site} -p${DB_PASSWORD:-admin123} ${DB_NAME:-ameen_site} < /home/frappe/frappe-bench/dump.sql
    else
         echo "No dump file found. Installing fresh site..."
         bench --site ${SITE_NAME:-erpnext.localhost} reinstall --yes
    fi
else
    echo "Site appears ready. Running migrate..."
fi

# Always migrate to ensure everything is in sync
bench --site ${SITE_NAME:-erpnext.localhost} migrate

# Set default site
bench use ${SITE_NAME:-erpnext.localhost}

# Run bench serve
bench serve --port 8000
