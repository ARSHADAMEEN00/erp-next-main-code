# Final Deployment Instructions

## Files to Share with Server Admin

Your server admin needs these files:
- `Dockerfile` (fixed version)
- `docker-compose.yml` (fixed version) 
- `docker-entrypoint.sh` (fixed version)
- `.env.production`
- `ameen_site_ready_dump.sql`
- `nginx.conf`

## Deployment Commands

```bash
# 1. Extract the tar.gz file
tar -xvzf erpnext-ameen-production-final.tar.gz

# 2. Build and run containers
docker-compose --env-file .env.production up -d --build

# 3. Check status
docker-compose ps
docker-compose logs -f
```

## Access Points

- **Frontend**: http://your-server-ip (nginx)
- **Backend**: http://your-server-ip:8000 (direct bench)

## Default Credentials

- **Admin Username**: Administrator
- **Admin Password**: admin (or whatever you set in .env.production)

## Troubleshooting

If issues occur:
```bash
# Check logs
docker-compose logs -f backend

# Rebuild without cache
docker-compose build --no-cache

# Restart services
docker-compose restart
```
