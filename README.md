# ERPNext Docker Deployment Guide

## 📦 What's Included

This Docker setup includes:

- **Frappe Framework** (core)
- **ERPNext** (accounting & business features)
- **ameen_app** (your custom app from GitHub)
- **MariaDB** (database)
- **Redis** (cache & queue)
- **Nginx** (web server)
- **Background Workers** (for async tasks)
- **Scheduler** (for cron jobs)

brew install mariadb
brew services start mariadb
brew install redis && brew services start redis

bench --site ameenSite backup && LATEST_BACKUP=$(ls -t sites/ameenSite/private/backups/*-database.sql.gz | head -n 1) && cp "$LATEST_BACKUP" ../latest_backup.sql.gz && gunzip -f ../latest_backup.sql.gz && mv ../latest_backup.sql ../ameen_site_ready_dump.sql

---

## 🚀 Quick Start

# 1. Stop containers and remove old volumes (Clears old DB)

docker-compose down -v

# 2. Build and Start (This takes a few minutes)

docker-compose up --build -d

docker-compose logs -f backend

### Prerequisites

Make sure you have installed:

- Docker (version 20.10+)
- Docker Compose (version 2.0+)

Check versions:

```bash
docker --version
docker-compose --version
```

### Step 1: Prepare Environment

```bash
cd /Users/ameenarshad/Projects/Frappe-demo/frappe-docker

# Copy environment template
cp .env.example .env

# Edit .env file with your preferences (optional)
nano .env
```

### Step 2: Build and Start

```bash
# Build the Docker image (first time only, takes 10-15 minutes)
docker-compose build

# Start all services
docker-compose up -d
```

### Step 3: Wait for Initialization

The first time you run this, it will:

1. Create a new ERPNext site
2. Install ERPNext app
3. Install your ameen_app
4. Set up the database

This takes about 5-10 minutes. Monitor progress:

````bash
## 🚀 How to Use (For Server Admin)

1.  **Extract the files:**
    ```bash
    tar -xzf erpnext-ameen-docker-deployment.tar.gz
    cd frappe-docker
    ```

2.  **Configure Environment (Verify DB Configuration):**
    The configuration is already set to connect to your existing MariaDB on the host (`127.0.0.1:3307` via Docker bridge).
    Check `.env`:
    ```bash
    cat .env
    # Should show:
    # DB_HOST=172.17.0.1
    # DB_PORT=3307
    # DB_NAME=ameen_site
    # DB_USER=ameen_site
    ```

3.  **Start the containers:**
    ```bash
    docker-compose up -d
    ```

4.  **Access the site:**
    Open `http://<your-server-ip>` in your browser.

    *   **Username:** Administrator
    *   **Password:** admin

---

## 🛠 Services

This setup launches the following services:

*   **ERPNext Backend:** `erpnext_backend` (Connects to your host MariaDB)
*   **Redis Cache:** `erpnext_redis_cache`
*   **Redis Queue:** `erpnext_redis_queue`
*   **Nginx Web Server:** `erpnext_nginx`
*   **Worker:** `erpnext_worker`
*   **Scheduler:** `erpnext_scheduler`

> **Note:** We are NOT running a database container. The application connects directly to the MariaDB instance running on your server at port 3307.

### Container won't start

```bash
# Check logs
docker-compose logs backend

# Check if ports are already in use
lsof -i :80
lsof -i :8000

# Remove and recreate
docker-compose down -v
docker-compose up -d
````

### Database connection errors

```bash
# Check if database is healthy
docker-compose ps

# Restart database
docker-compose restart db

# Wait for database to be ready
docker-compose exec db mysqladmin ping -h localhost
```

### "Site not found" error

```bash
# List sites
docker-compose exec backend bench --site erpnext.localhost list-sites

# If site doesn't exist, create it:
docker-compose exec backend bench new-site erpnext.localhost --db-root-password admin123 --admin-password admin
docker-compose exec backend bench --site erpnext.localhost install-app erpnext
docker-compose exec backend bench --site erpnext.localhost install-app ameen_app
```

### Clear everything and start fresh

```bash
# WARNING: This deletes all data!
docker-compose down -v
docker-compose up -d
```

---

## 📤 Sharing with Server Administrator

### Option 1: Share Docker Setup Files

Send your server admin these files:

```
frappe-docker/
├── Dockerfile
├── docker-compose.yml
├── nginx.conf
├── .env.example
└── README.md (this file)
```

They just need to:

```bash
# 1. Copy .env.example to .env and customize
cp .env.example .env

# 2. Build and run
docker-compose up -d
```

### Option 2: Push to Docker Hub (Recommended for Production)

```bash
# Build image
docker build -t yourusername/erpnext-ameen:latest .

# Push to Docker Hub
docker login
docker push yourusername/erpnext-ameen:latest

# Share docker-compose.yml with updated image reference
```

Then update docker-compose.yml:

```yaml
backend:
  image: yourusername/erpnext-ameen:latest # Instead of build: .
```

---

## 🔒 Production Considerations

### Security

1. **Change default passwords** in .env:

   ```env
   DB_ROOT_PASSWORD=your-strong-password-here
   ADMIN_PASSWORD=your-admin-password-here
   ```

2. **Disable developer mode**:

   ```env
   DEVELOPER_MODE=0
   ```

3. **Use HTTPS** (add SSL certificates to nginx)

4. **Restrict API access** (remove `allow_guest=True` from production APIs)

### Performance

1. **Increase resources** in docker-compose.yml:

   ```yaml
   backend:
     deploy:
       resources:
         limits:
           cpus: "2"
           memory: 4G
   ```

2. **Use production-grade database**:
   - Consider external managed database (AWS RDS, etc.)
   - Regular backups

3. **Enable caching**:
   - Redis is already configured
   - Consider CDN for static assets

---

## 📊 Monitoring

### Health Checks

```bash
# Check all services
docker-compose ps

# Check specific service health
docker-compose exec backend bench doctor
```

### Resource Usage

```bash
# View resource usage
docker stats

# View disk usage
docker system df
```

---

## 🆘 Support

### Logs Location

Inside containers:

- Backend logs: `/home/frappe/frappe-bench/logs/`
- Database logs: Check with `docker-compose logs db`

On host (persisted):

```bash
# View volume location
docker volume inspect frappe-docker_logs_data
```

### Common Issues

| Issue                     | Solution                                       |
| ------------------------- | ---------------------------------------------- |
| Port 80 already in use    | Change port in docker-compose.yml: `"8080:80"` |
| Out of memory             | Increase Docker memory limit in Docker Desktop |
| Slow performance          | Allocate more CPU/RAM to Docker                |
| Can't access from network | Change `SITE_NAME` to your server IP/domain    |

---

## 📝 Environment Variables Reference

| Variable           | Default           | Description                    |
| ------------------ | ----------------- | ------------------------------ |
| `DB_ROOT_PASSWORD` | admin123          | MariaDB root password          |
| `DB_NAME`          | erpnext           | Database name                  |
| `DB_USER`          | erpnext           | Database user                  |
| `DB_PASSWORD`      | erpnext123        | Database password              |
| `SITE_NAME`        | erpnext.localhost | Site domain name               |
| `ADMIN_PASSWORD`   | admin             | ERPNext admin password         |
| `DEVELOPER_MODE`   | 1                 | Enable developer mode (0 or 1) |

---

## 🔄 Update Strategy

### Update ERPNext

```bash
# Pull latest ERPNext image
docker-compose pull

# Rebuild with latest
docker-compose build --no-cache

# Restart
docker-compose down
docker-compose up -d
```

### Update ameen_app

```bash
# Method 1: Rebuild image (if you changed Dockerfile)
docker-compose build backend
docker-compose up -d

# Method 2: Update inside container
docker-compose exec backend bash -c "cd apps/ameen_app && git pull"
docker-compose exec backend bench --site erpnext.localhost migrate
docker-compose restart backend
```

---

## ✅ Deployment Checklist

- [ ] Docker and Docker Compose installed
- [ ] `.env` file created and customized
- [ ] Ports 80, 8000 available
- [ ] At least 4GB RAM allocated to Docker
- [ ] `ameen_app` repository is public or credentials configured
- [ ] Built image: `docker-compose build`
- [ ] Started services: `docker-compose up -d`
- [ ] Waited for initialization (5-10 minutes)
- [ ] Accessed http://localhost successfully
- [ ] Logged in with Administrator credentials
- [ ] Verified ameen_app is installed
- [ ] Tested API endpoints
- [ ] Configured backups

---

**Created:** 2026-02-11  
**For:** Ameen App - Docker Deployment  
**Repository:** https://github.com/ARSHADAMEEN00/frappe-first-custom-app
