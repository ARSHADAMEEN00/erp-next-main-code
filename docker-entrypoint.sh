#!/bin/bash
set -e

echo "Starting ERPNext with fixed configuration..."

SITE_NAME="${SITE_NAME:-erpnext.localhost}"
DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME:-ameen_site}"
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-admin123}"
DB_PASSWORD="${DB_PASSWORD:-admin123}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
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
    echo "Restoring database from dump file (ameen_site_ready_dump.sql)..."
    mysql -h "${DB_HOST}" -P "${DB_PORT}" -u root -p"${DB_ROOT_PASSWORD}" "${DB_NAME}" \
        < /home/frappe/frappe-bench/dump.sql \
        && echo "Database restored successfully!" \
        || echo "Dump restore failed or already restored, continuing..."
fi

# ─── Step 4: Fix user permissions AFTER dump restore ─────────────────────────
# The dump may overwrite grants, so we re-apply them here
echo "Fixing database user permissions..."
mysql -h "${DB_HOST}" -P "${DB_PORT}" -u root -p"${DB_ROOT_PASSWORD}" << SQL
DROP USER IF EXISTS '${DB_NAME}'@'localhost';
DROP USER IF EXISTS '${DB_NAME}'@'%';
CREATE USER '${DB_NAME}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_NAME}'@'%';
FLUSH PRIVILEGES;
SQL
echo "Permissions fixed!"

# ─── Step 5: Create site if it doesn't exist ─────────────────────────────────
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

# ─── Step 6: Run migrations ───────────────────────────────────────────────────
echo "Running migrations..."
bench --site "${SITE_NAME}" migrate || echo "Migration completed with warnings (non-fatal)"

# ─── Step 7: Install custom app ──────────────────────────────────────────────
if ! bench --site "${SITE_NAME}" list-apps 2>/dev/null | grep -q "ameen_app"; then
    echo "Installing ameen_app..."
    bench --site "${SITE_NAME}" install-app ameen_app || echo "ameen_app install failed or already installed"
fi

# ─── Step 8: Final setup ──────────────────────────────────────────────────────
bench use "${SITE_NAME}" || true
mkdir -p "${SITE_PATH}/locks"
mkdir -p "${SITE_PATH}/logs"

echo "Starting ERPNext server..."
exec bench serve --port 8000 --noreload
