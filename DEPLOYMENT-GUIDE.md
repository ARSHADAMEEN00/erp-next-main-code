# ERPNext Production Deployment Guide

## 🚀 Quick Deployment for Server Admin

### Prerequisites

- Docker (version 20.10+)
- Docker Compose (version 2.0+)

### Step 1: Extract Files

```bash
tar -xzf erpnext-ameen-production.tar.gz
cd erpnext-ameen-production
```

### Step 2: Configure Environment

```bash
# Copy environment template to .env (Docker Compose standard)
cp .env.production .env

# Edit .env file with your preferences (optional)
nano .env
```

### Step 3: Build and Start

```bash
# Build the Docker image (first time only, takes 10-15 minutes)
docker-compose -f docker-compose-production.yml build

# Start all services
docker-compose -f docker-compose-production.yml up -d
```

### Step 4: Access the Application

- **URL**: http://your-server-ip
- **Username**: Administrator
- **Password**: admin (change this in production!)

## 📦 What's Included

### Services

- **MariaDB Database** (fully containerized)
- **Redis Cache & Queue**
- **ERPNext Backend** (with ameen_app pre-installed)
- **Nginx Web Server**
- **Background Workers**
- **Scheduler**

### Database

- Database is created inside Docker containers
- No external database setup required
- Data persists in Docker volumes
- Pre-loaded with ameen_site data from dump.sql

## 🔧 Configuration

### Environment Variables (.env)

| Variable           | Default           | Description                                   |
| ------------------ | ----------------- | --------------------------------------------- |
| `DB_ROOT_PASSWORD` | admin123          | MariaDB root password                         |
| `DB_NAME`          | ameen_site        | Database name                                 |
| `DB_USER`          | ameen_site        | Database user                                 |
| `DB_PASSWORD`      | admin123          | Database password                             |
| `SITE_NAME`        | erpnext.localhost | Site domain                                   |
| `ADMIN_PASSWORD`   | admin             | ERPNext admin password                        |
| `DEVELOPER_MODE`   | 0                 | Production mode (0=production, 1=development) |

### Port Configuration

- **Port 80**: HTTP web access
- **Port 443**: HTTPS (SSL certificates needed)
- **Port 8000**: Direct backend access
- **Port 3306**: Database (internal)

## 🛠 Management Commands

### Check Status

```bash
docker-compose -f docker-compose-production.yml ps
```

### View Logs

```bash
# All services
docker-compose -f docker-compose-production.yml logs

# Specific service
docker-compose -f docker-compose-production.yml logs backend
```

### Stop Services

```bash
docker-compose -f docker-compose-production.yml down
```

### Backup Database

```bash
docker-compose -f docker-compose-production.yml exec db mysqldump -u root -p$DB_ROOT_PASSWORD ameen_site > backup.sql
```

## 🔒 Security Recommendations

1. **Change Default Passwords**
   - Update `DB_ROOT_PASSWORD` in .env
   - Update `ADMIN_PASSWORD` in .env
   - Change ERPNext admin password after first login

2. **Enable HTTPS**
   - Add SSL certificates to nginx configuration
   - Update port 443 configuration

3. **Network Security**
   - Configure firewall rules
   - Restrict database port (3306) access

4. **Regular Backups**
   - Set up automated database backups
   - Backup Docker volumes

## 📊 Monitoring

### Health Checks

```bash
# Check all services
docker-compose -f docker-compose-production.yml ps

# Check database
docker-compose -f docker-compose-production.yml exec db mysqladmin ping -h localhost
```

### Resource Usage

```bash
# View resource usage
docker stats
```

## 🆘 Troubleshooting

### Common Issues

**Port Already in Use**

```bash
# Check what's using port 80
sudo lsof -i :80
# Stop conflicting service or change port in docker-compose-production.yml
```

**Database Connection Issues**

```bash
# Restart database service
docker-compose -f docker-compose-production.yml restart db

# Check database logs
docker-compose -f docker-compose-production.yml logs db
```

**Site Not Loading**

```bash
# Restart all services
docker-compose -f docker-compose-production.yml restart

# Check nginx logs
docker-compose -f docker-compose-production.yml logs nginx
```

### Complete Reset (WARNING: Deletes all data)

```bash
docker-compose -f docker-compose-production.yml down -v
docker-compose -f docker-compose-production.yml up -d
```

## 📞 Support

This deployment includes:

- ERPNext v15.10.0
- Custom ameen_app (pre-installed)
- MariaDB with sample data
- Production-ready configuration

For application-specific issues, refer to ERPNext documentation or contact your system administrator.

---

**Deployment Package Created**: 2026-02-17
**Includes**: Complete Docker setup with database
