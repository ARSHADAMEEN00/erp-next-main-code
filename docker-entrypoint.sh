#!/bin/bash
set -e

echo "Starting ERPNext with fixed configuration..."

SITE_NAME="${SITE_NAME:-focusmotors.localhost}"
DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-focusmotors_prod}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-Fr@ppe$Root#2024!}"
DB_PASSWORD="${DB_PASSWORD:-Fm@Secure#2024!}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-Fm@Admin#2024!}"
SITE_PATH="/home/frappe/frappe-bench/sites/${SITE_NAME}"

# ─── Step 1: Wait for MariaDB ────────────────────────────────────────────────
echo "Waiting for MariaDB to be ready..."
until mysql -h "${DB_HOST}" -P "${DB_PORT}" -u root -p"${DB_ROOT_PASSWORD}" -e "SELECT 1;" > /dev/null 2>&1; do
    echo "  MariaDB not ready yet, retrying in 3s..."
    sleep 3
done
echo "MariaDB is ready!"

# ─── Step 2: Update common_site_config.json ──────────────────────────────────
echo "Updating common_site_config.json..."
mkdir -p /home/frappe/frappe-bench/sites
cat > /home/frappe/frappe-bench/sites/common_site_config.json << EOF
{
    "redis_cache": "redis://redis-cache:6379",
    "redis_queue": "redis://redis-queue:6379",
    "redis_socketio": "redis://redis-queue:6379",
    "db_host": "${DB_HOST}",
    "db_port": ${DB_PORT}
}
EOF

# ─── Step 3: Create DB and restore dump ──────────────────────────────────────
echo "Creating database if not exists..."
mysql -h "${DB_HOST}" -P "${DB_PORT}" -u root -p"${DB_ROOT_PASSWORD}" -e \
    "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

if [ -f /home/frappe/frappe-bench/dump.sql ]; then
    echo "Restoring database from dump file (dump.sql)..."
    mysql -h "${DB_HOST}" -P "${DB_PORT}" -u root -p"${DB_ROOT_PASSWORD}" "${DB_NAME}" \
        < /home/frappe/frappe-bench/dump.sql \
        && echo "Database restored successfully!" \
        || echo "Dump restore failed or already restored, continuing..."
fi

# ─── Step 4: Write site_config.json with OUR password BEFORE granting ────────
echo "Writing site_config.json with known password..."
mkdir -p "${SITE_PATH}"
cat > "${SITE_PATH}/site_config.json" << EOF
{
    "db_name": "${DB_NAME}",
    "db_password": "${DB_PASSWORD}",
    "db_host": "${DB_HOST}",
    "db_port": ${DB_PORT},
    "admin_password": "${ADMIN_PASSWORD}"
}
EOF
echo "site_config.json written!"

# ─── Step 4b: Create required site directories early ─────────────────────────
echo "Creating site directories..."
mkdir -p "${SITE_PATH}/logs"
mkdir -p "${SITE_PATH}/locks"
mkdir -p "${SITE_PATH}/public"
touch "${SITE_PATH}/logs/database.log"
echo "Site directories ready!"

# ─── Step 5: Grant DB user with OUR known password ───────────────────────────
echo "Fixing database user permissions..."
mysql -h "${DB_HOST}" -P "${DB_PORT}" -u root -p"${DB_ROOT_PASSWORD}" << SQL
DROP USER IF EXISTS 'fm_dbuser'@'localhost';
DROP USER IF EXISTS 'fm_dbuser'@'%';
CREATE USER 'fm_dbuser'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO 'fm_dbuser'@'%';
FLUSH PRIVILEGES;
SQL
echo "Permissions fixed! DB user 'fm_dbuser' password set to '${DB_PASSWORD}'"

# ─── Step 6: Verify connection works ─────────────────────────────────────────
echo "Verifying DB connection as '${DB_NAME}' user..."
until mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "fm_dbuser" -p"${DB_PASSWORD}" "${DB_NAME}" -e "SELECT 1;" > /dev/null 2>&1; do
    echo "  Connection not ready yet, retrying in 2s..."
    sleep 2
done
echo "DB connection verified successfully!"

# ─── Step 7: Create site if it doesn't exist ─────────────────────────────────
if [ ! -d "${SITE_PATH}" ]; then
    echo "Site directory not found. Creating site..."
    bench new-site "${SITE_NAME}" \
        --db-root-username root \
        --db-root-password "${DB_ROOT_PASSWORD}" \
        --db-name "${DB_NAME}" \
        --admin-password "${ADMIN_PASSWORD}" \
        --no-mariadb-socket \
        || echo "Site creation failed, it may already exist"
else
    echo "Site already exists at ${SITE_PATH}"
fi

# ─── Step 8: Run migrations ───────────────────────────────────────────────────
echo "Running migrations..."
bench --site "${SITE_NAME}" migrate || echo "Migration completed with warnings (non-fatal)"

# ─── Step 9: Install custom app ──────────────────────────────────────────────
if ! bench --site "${SITE_NAME}" list-apps 2>/dev/null | grep -q "focusmotors"; then
    echo "Installing focusmotors app..."
    bench --site "${SITE_NAME}" install-app focusmotors || echo "focusmotors app install failed or already installed"
fi

# ─── Step 10: Final setup ─────────────────────────────────────────────────────
bench use "${SITE_NAME}" || true
mkdir -p "${SITE_PATH}/locks"
mkdir -p "${SITE_PATH}/logs"
mkdir -p "${SITE_PATH}/public"

echo "Starting ERPNext server..."
exec bench serve --port 8000 --noreload
