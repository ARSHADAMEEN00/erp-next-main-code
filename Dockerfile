# Frappe ERPNext with Custom App (ameen_app) - Fixed Version
# This Dockerfile builds a complete, properly initialized Frappe bench

FROM --platform=linux/amd64 frappe/erpnext:v15.10.0

# Switch to root user for initial setup
USER root

# Set working directory
WORKDIR /home/frappe/frappe-bench

# Copy local bench configuration files from frappe-bench directory
COPY frappe-bench/Procfile ./
COPY frappe-bench/patches.txt ./
COPY frappe-bench/config/ ./config/

# Copy local apps (preserves your edits to frappe/erpnext/custom apps)
COPY frappe-bench/apps ./apps

# Fix ownership to frappe user
RUN chown -R frappe:frappe /home/frappe/frappe-bench

# Switch to frappe user for build commands
USER frappe

# Install app dependencies (Must be run as frappe user)
RUN bench setup requirements
RUN pip install -e apps/ameen_app
RUN bench build --app frappe

# Switch back to root for final setup (if needed, though usually not)
USER root

# Switch back to root for final setup
USER root

# Expose port 8000
EXPOSE 8000

# Switch back to frappe user for runtime
USER frappe

# Default command
CMD ["bench", "start"]
