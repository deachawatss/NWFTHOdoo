# Odoo 17 Docker Setup

This Docker configuration provides a complete containerized environment for running Odoo 17 with PostgreSQL database on server IP 192.168.0.21.

## Quick Start

### 1. Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 4GB RAM available
- 20GB disk space

### 2. Configuration

Edit the `.env` file to customize your environment:

```bash
# Database settings
POSTGRES_DB=odoo
POSTGRES_USER=odoo
POSTGRES_PASSWORD=odoo123

# Server settings
SERVER_IP=192.168.0.21
ODOO_HTTP_PORT=8069
ODOO_LONGPOLLING_PORT=8072
```

### 3. Start Services

```bash
# Development mode with auto-reload
docker-compose up -d

# Production mode
docker-compose -f docker-compose.prod.yml up -d
```

### 4. Access Your Odoo Instance

- **Odoo Web Interface**: `http://192.168.0.21:8069`
- **pgAdmin**: `http://192.168.0.21:5050` (optional)
- **Database**: `192.168.0.21:5432`

Default credentials:
- **Odoo Admin**: `admin` / `admin`
- **pgAdmin**: `admin@odoo.local` / `admin`

## Services Overview

### Core Services

- **odoo**: Main Odoo 17 application server
- **db**: PostgreSQL 13 database
- **redis**: Redis for caching (optional)
- **nginx**: Reverse proxy for production (prod only)

### Optional Services

- **pgadmin**: Web-based database management
- **backup**: Automated backup service (prod only)

## Directory Structure

```
Odoo17/
├── docker-compose.yml          # Development configuration
├── docker-compose.prod.yml     # Production configuration
├── Dockerfile                  # Odoo container image
├── docker-entrypoint.sh       # Container initialization script
├── .dockerignore              # Build context exclusions
├── .env                       # Environment variables
├── addons/                    # Standard Odoo addons
├── custom_addons/            # Your custom addons
├── backup/                   # Database backups
└── README-Docker.md          # This file
```

## Common Commands

### Development

```bash
# Start development environment
docker-compose up -d

# View logs
docker-compose logs -f odoo

# Restart Odoo service
docker-compose restart odoo

# Install new module
docker-compose exec odoo python3 /opt/odoo/odoo-bin -d odoo -i module_name

# Update module
docker-compose exec odoo python3 /opt/odoo/odoo-bin -d odoo -u module_name

# Open shell in container
docker-compose exec odoo bash

# Stop all services
docker-compose down
```

### Production

```bash
# Start production environment
docker-compose -f docker-compose.prod.yml up -d

# View production logs
docker-compose -f docker-compose.prod.yml logs -f odoo

# Scale Odoo instances
docker-compose -f docker-compose.prod.yml up -d --scale odoo=3

# Production backup
docker-compose -f docker-compose.prod.yml exec backup /backup.sh

# Stop production environment
docker-compose -f docker-compose.prod.yml down
```

### Database Management

```bash
# Create database backup
docker-compose exec db pg_dump -U odoo odoo > backup_$(date +%Y%m%d).sql

# Restore database
docker-compose exec -T db psql -U odoo odoo < backup_file.sql

# Access database directly
docker-compose exec db psql -U odoo odoo

# Drop and recreate database
docker-compose exec db dropdb -U odoo odoo
docker-compose exec db createdb -U odoo odoo
```

## Customization

### Adding Custom Addons

1. Place your custom addons in the `custom_addons/` directory
2. Restart the Odoo service:
   ```bash
   docker-compose restart odoo
   ```

### Modifying Configuration

Edit `odoo.conf` and restart:
```bash
docker-compose restart odoo
```

### Environment Variables

Key environment variables in `.env`:

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_DB` | Database name | `odoo` |
| `POSTGRES_USER` | Database user | `odoo` |
| `POSTGRES_PASSWORD` | Database password | `odoo123` |
| `SERVER_IP` | Server IP address | `192.168.0.21` |
| `ODOO_HTTP_PORT` | Odoo web port | `8069` |
| `ODOO_ADMIN_PASSWORD` | Master password | `admin` |
| `ODOO_DEV_MODE` | Development options | `reload,qweb,werkzeug,xml` |

## Troubleshooting

### Common Issues

1. **Port already in use**
   ```bash
   # Check what's using the port
   sudo netstat -tulpn | grep :8069
   
   # Kill the process or change port in .env
   ```

2. **Database connection failed**
   ```bash
   # Check database logs
   docker-compose logs db
   
   # Verify database is running
   docker-compose exec db pg_isready -U odoo
   ```

3. **Module not found**
   ```bash
   # Verify addon path
   docker-compose exec odoo ls -la /opt/odoo/custom_addons/
   
   # Check addons_path in odoo.conf
   docker-compose exec odoo cat /opt/odoo/odoo.conf | grep addons_path
   ```

4. **Permission denied**
   ```bash
   # Fix file permissions
   sudo chown -R 999:999 ./custom_addons/
   sudo chmod -R 755 ./custom_addons/
   ```

### Logs and Debugging

```bash
# View all service logs
docker-compose logs

# Follow specific service logs
docker-compose logs -f odoo
docker-compose logs -f db

# Check container status
docker-compose ps

# Inspect container
docker-compose exec odoo env
```

### Performance Tuning

For production environments, consider:

1. **Increase worker processes** in `odoo.conf`:
   ```ini
   workers = 4
   max_cron_threads = 2
   ```

2. **Optimize PostgreSQL** in `pg_config/postgresql.conf`:
   ```
   shared_buffers = 256MB
   effective_cache_size = 1GB
   ```

3. **Enable Redis caching** by uncommenting Redis service

## Security Considerations

### Production Security

1. **Change default passwords** in `.env`
2. **Use SSL certificates** (configure nginx service)
3. **Restrict database access** to container network only
4. **Enable firewall rules** for ports 8069, 8072
5. **Regular security updates** for base images

### Network Security

```bash
# Create isolated network
docker network create odoo-secure

# Run with custom network
docker-compose -f docker-compose.prod.yml --project-name odoo-prod up -d
```

## Backup and Recovery

### Automated Backups

Production environment includes automated backup service:

```bash
# Manual backup
docker-compose -f docker-compose.prod.yml exec backup /backup.sh

# Restore from backup
docker-compose -f docker-compose.prod.yml exec backup /restore.sh backup_file.sql
```

### Manual Backup

```bash
# Database backup
docker-compose exec db pg_dump -U odoo odoo | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz

# Filestore backup
docker-compose exec odoo tar -czf /tmp/filestore_backup.tar.gz -C /var/lib/odoo filestore/
docker cp $(docker-compose ps -q odoo):/tmp/filestore_backup.tar.gz ./filestore_backup.tar.gz
```

## Monitoring and Maintenance

### Health Checks

All services include health checks:

```bash
# Check service health
docker-compose ps

# Manual health check
docker-compose exec odoo curl -f http://localhost:8069/web/health
```

### Log Rotation

Logs are automatically rotated in production. Manual rotation:

```bash
# Rotate logs
docker-compose exec odoo logrotate /etc/logrotate.d/odoo
```

### Updates

```bash
# Update images
docker-compose pull

# Rebuild with latest changes
docker-compose build --no-cache

# Update and restart
docker-compose up -d --build
```

## Support

For issues specific to this Docker setup:

1. Check the logs: `docker-compose logs -f`
2. Verify configuration: `docker-compose config`
3. Test connectivity: `docker-compose exec odoo ping db`
4. Review resource usage: `docker stats`

For Odoo-specific issues, refer to the main `CLAUDE.md` file in the project root.

## License

This Docker configuration is provided under the same license as the Odoo project.