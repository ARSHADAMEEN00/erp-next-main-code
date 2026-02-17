# Frappe ERPNext with Custom App (ameen_app)
# This Dockerfile builds an image with Frappe, ERPNext, and your custom ameen_app

FROM --platform=linux/amd64 frappe/erpnext:v15.10.0

# Switch to frappe user
USER frappe

# Set working directory
WORKDIR /home/frappe/frappe-bench

# Install your custom app from GitHub
RUN bench get-app --branch main https://github.com/ARSHADAMEEN00/frappe-first-custom-app.git

# Switch back to root for any final setup
USER root

# Expose port 8000 for development
EXPOSE 8000

# Switch back to frappe user
USER frappe

# Default command (will be overridden by docker-compose)
CMD ["bench", "start"]
