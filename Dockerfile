# Frappe ERPNext with Custom App (ameen_app) - Fixed Version
# This Dockerfile builds a complete, properly initialized Frappe bench

FROM --platform=linux/amd64 frappe/erpnext:v15.10.0

# Switch to root user for initial setup
USER root

# Set working directory
WORKDIR /home/frappe/frappe-bench

# Copy local bench configuration files as root first
COPY Procfile ./
COPY patches.txt ./
COPY config/ ./config/

# Fix ownership
RUN chown -R frappe:frappe /home/frappe/frappe-bench

# Switch to frappe user
USER frappe

# Install your custom app from GitHub
RUN bench get-app --branch main https://github.com/ARSHADAMEEN00/frappe-first-custom-app.git

# Create new site with proper configuration
RUN bench new-site ${SITE_NAME:-erpnext.localhost} \
    --db-host ${DB_HOST:-db} \
    --db-port ${DB_PORT:-3306} \
    --db-name ${DB_NAME:-ameen_site} \
    --db-user ${DB_USER:-ameen_site} \
    --db-password ${DB_PASSWORD:-admin123} \
    --admin-password ${ADMIN_PASSWORD:-admin} \
    --install-app ameen_app \
    --no-mariadb-socket

# Switch back to root for final setup
USER root

# Expose port 8000
EXPOSE 8000

# Switch back to frappe user for runtime
USER frappe

# Default command
CMD ["bench", "start"]
