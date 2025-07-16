# Odoo 17 Production Setup for Windows Server 192.168.0.21

## Quick Start

1. **Double-click `start-production.bat`** to start Odoo
2. **Access Odoo at: http://192.168.0.21:8069**
3. **To stop: Double-click `stop-production.bat`**

## What's Included

This simplified production setup includes only essential files:

- `docker-compose.yml` - Main production configuration
- `Dockerfile` - Odoo application container
- `Dockerfile.backup` - Backup service container
- `docker-entrypoint.sh` - Container startup script
- `start-production.bat` - Windows startup script
- `stop-production.bat` - Windows stop script

## Production Features

✅ **Optimized for Windows Server 192.168.0.21**
✅ **Automatic daily backups**
✅ **Redis caching for performance**
✅ **Health checks and auto-restart**
✅ **Resource limits for stability**
✅ **Secure database credentials**

## Services

| Service | Container | Purpose | Port |
|---------|-----------|---------|------|
| Odoo | `odoo17_app` | Main application | 8069 |
| PostgreSQL | `odoo17_db` | Database | Internal |
| Redis | `odoo17_redis` | Cache/Sessions | Internal |
| Backup | `odoo17_backup` | Auto backup | Internal |

## Manual Commands

If you prefer command line:

```bash
# Start production environment
docker-compose up -d

# Stop environment
docker-compose down

# View logs
docker-compose logs -f

# View service status
docker-compose ps

# Manual backup
docker-compose exec backup /scripts/backup.sh
```

## Database Configuration

- **Database Name**: `odoo_prod`
- **Username**: `odoo_prod`
- **Password**: `OdooSecure2024!`
- **Host**: `db` (internal)

## Backup Configuration

- **Location**: `./backup/` directory
- **Frequency**: Daily (automatic)
- **Retention**: 7 days
- **Includes**: Database + file attachments

## First Time Setup

1. Start services: `start-production.bat`
2. Wait 2-3 minutes for initial setup
3. Open browser: http://192.168.0.21:8069
4. Create master password
5. Create your first database

## Troubleshooting

**Container won't start?**
- Check Docker Desktop is running
- Run `docker-compose logs` to see errors

**Can't access http://192.168.0.21:8069?**
- Check Windows Firewall port 8069
- Verify server IP is 192.168.0.21

**Need to change password?**
- Edit `docker-compose.yml`
- Change `OdooSecure2024!` to your password
- Run `start-production.bat` again

**Need more memory?**
- Edit `docker-compose.yml`
- Increase memory limits in deploy section

## Directory Structure

```
Odoo17/
├── docker-compose.yml      # Main configuration
├── Dockerfile              # Odoo container
├── Dockerfile.backup       # Backup container
├── docker-entrypoint.sh    # Startup script
├── start-production.bat    # Start script
├── stop-production.bat     # Stop script
├── odoo.conf               # Odoo configuration
├── addons/                 # Standard Odoo modules
├── custom_addons/          # Your custom modules
└── backup/                 # Backup files
```

## Support

For issues or customization, check the logs:
```bash
docker-compose logs -f odoo
```