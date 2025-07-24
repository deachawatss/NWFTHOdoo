# Docker Setup Guide for Odoo 17

## Prerequisites

### 1. Install Docker Desktop on Windows
1. Download Docker Desktop from https://docker.com/products/docker-desktop
2. Install Docker Desktop
3. Enable WSL 2 integration:
   - Open Docker Desktop
   - Go to Settings → Resources → WSL Integration
   - Enable integration with your WSL 2 distro (Ubuntu)
   - Click "Apply & Restart"

### 2. Verify Docker in WSL2
```bash
# Check Docker is available
docker --version
docker-compose --version

# Test Docker
docker run hello-world
```

## Quick Start

### 1. Start Odoo Docker Environment
```bash
# Navigate to your Odoo directory
cd /home/deachawat/dev/projects/Odoo/Odoo17

# Start all services
./start-docker.sh
```

### 2. Access Your Applications
- **Odoo**: http://localhost:8069
- **PgAdmin**: http://localhost:8080
- **Database**: localhost:5432

### 3. Login Credentials (Same as Development)
- **Odoo Master Password**: 1234
- **Database**: admin/1234  
- **PgAdmin**: admin@localhost / 1234

## Docker Commands

### Basic Operations
```bash
# Start environment
./start-docker.sh

# Stop environment
./stop-docker.sh

# View logs
./docker-logs.sh              # All services
./docker-logs.sh odoo          # Odoo only
./docker-logs.sh db            # Database only
```

### Advanced Operations
```bash
# Restart specific service
docker-compose restart odoo

# Access Odoo container shell
docker-compose exec odoo bash

# Access database container shell
docker-compose exec db psql -U admin -d postgres

# Update Odoo image
docker-compose pull odoo
docker-compose up -d odoo

# View container status
docker-compose ps

# Remove everything (including data)
docker-compose down -v
```

## Custom Addons

Your custom addons in `./custom_addons/` are automatically mounted into the Odoo container at `/mnt/extra-addons/`.

### Adding New Custom Addons
1. Place your addon in `./custom_addons/`
2. Restart Odoo: `docker-compose restart odoo`
3. Update module list in Odoo interface

## Configuration

### Docker-Specific Configuration
- **Main Config**: `./config/odoo.conf` (mounted to container)
- **Environment**: `.env.docker` (Docker environment variables)
- **Compose**: `docker-compose.yml` (service definitions)

### Persistent Data
Data is stored in Docker volumes:
- **Database**: `odoo17_odoo_db_data`
- **Odoo Files**: `odoo17_odoo_web_data`

## Development Workflow

### 1. Code Changes
- Edit files in `./custom_addons/`
- Changes are immediately available (dev mode enabled)
- No restart needed for most changes

### 2. Configuration Changes  
- Edit `./config/odoo.conf`
- Restart: `docker-compose restart odoo`

### 3. Database Operations
- Use PgAdmin: http://localhost:8080
- Or direct connection: `PGPASSWORD=1234 psql -h localhost -U admin -d postgres`

## Troubleshooting

### Common Issues

**Docker not found in WSL2:**
```bash
# Enable WSL integration in Docker Desktop settings
```

**Port conflicts:**
```bash
# Stop conflicting services
sudo lsof -i :8069
sudo kill -9 <PID>
```

**Permission issues:**
```bash
# Fix file permissions
sudo chown -R $USER:$USER ./custom_addons
sudo chown -R $USER:$USER ./config
```

**Container won't start:**
```bash
# Check logs
./docker-logs.sh

# Reset environment
docker-compose down -v
./start-docker.sh
```

## Production Considerations

### Performance
- Increase workers in `./config/odoo.conf` for production
- Use external PostgreSQL for better performance
- Enable Redis for session storage

### Security
- Change default passwords
- Use environment variables for secrets
- Enable SSL/HTTPS
- Restrict database access

### Backup
```bash
# Database backup
docker-compose exec db pg_dump -U admin postgres > backup.sql

# Full backup (including files)
docker run --rm -v odoo17_odoo_web_data:/data -v $(pwd):/backup alpine tar czf /backup/odoo-files.tar.gz -C /data .
```

## Migration from Direct Installation

Your current setup is preserved:
- Same credentials (admin/1234)
- Same custom addons
- Same configuration structure
- Same database schema

Docker provides:
- ✅ Consistent environment
- ✅ Easy deployment  
- ✅ Version isolation
- ✅ Quick setup/teardown
- ✅ Production-ready