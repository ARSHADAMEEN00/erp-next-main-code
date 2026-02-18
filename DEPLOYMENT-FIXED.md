# Fixed Docker Deployment for ERPNext

## Issues Fixed

1. **Missing Procfile**: The original Dockerfile didn't properly copy the Procfile and bench configuration
2. **Database connection**: Fixed database user credentials in entrypoint script
3. **Container-friendly paths**: Removed host-specific Node.js path from Procfile
4. **Proper bench initialization**: Added proper site creation and app installation

## New Files Created

- `Dockerfile.fixed` - Properly initializes frappe-bench with all required files
- `docker-compose-fixed.yml` - Simplified compose file without version attribute
- `docker-entrypoint-fixed.sh` - Robust entrypoint with proper error handling

## How to Deploy

1. **Using the fixed setup**:
   ```bash
   docker-compose -f docker-compose-fixed.yml up -d --build
   ```

2. **Environment variables** (create `.env` file if needed):
   ```bash
   DB_ROOT_PASSWORD=admin123
   DB_NAME=ameen_site
   DB_USER=ameen_site
   DB_PASSWORD=admin123
   SITE_NAME=erpnext.localhost
   ADMIN_PASSWORD=admin
   ```

3. **Access the application**:
   - Frontend: http://localhost (nginx)
   - Backend: http://localhost:8000 (direct bench)

## Key Improvements

- **Proper file copying**: Procfile, patches.txt, and config/ are now copied into the container
- **Fixed ownership**: All files have correct frappe user ownership
- **Container-ready paths**: Removed absolute host paths from Procfile
- **Error handling**: Added proper error checking and exit codes
- **Redis wait**: Added Redis service dependency checks
- **App installation**: Ensures ameen_app is properly installed

## Troubleshooting

If you still encounter issues:

1. Check container logs:
   ```bash
   docker-compose -f docker-compose-fixed.yml logs -f backend
   ```

2. Verify database connectivity:
   ```bash
   docker-compose -f docker-compose-fixed.yml exec backend bench --site erpnext.localhost list-apps
   ```

3. Rebuild without cache:
   ```bash
   docker-compose -f docker-compose-fixed.yml build --no-cache
   ```

## Migration from Original

To migrate from the original setup:

1. Stop existing containers:
   ```bash
   docker-compose -f docker-compose-production.yml down
   ```

2. Start with fixed version:
   ```bash
   docker-compose -f docker-compose-fixed.yml up -d --build
   ```

The fixed version maintains all your data volumes and configurations.
