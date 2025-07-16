# Odoo 17 Production Deployment Guide for Windows Server

## Prerequisites

### 1. System Requirements
- **Windows Server 2019/2022** or **Windows 10/11 Pro**
- **8GB+ RAM** (16GB recommended)
- **50GB+ free disk space**
- **Static IP address** or **domain name**
- **Internet connection** for Docker images

### 2. Software Installation

#### Install Docker Desktop for Windows
1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop
2. Run the installer and enable WSL2 backend
3. Restart your computer
4. Open Docker Desktop and complete setup

#### Verify Installation
```powershell
# Open PowerShell as Administrator and run:
docker --version
docker-compose --version
```

## Step-by-Step Deployment

### Step 1: Prepare Configuration Files

#### 1.1 Configure Environment Variables
Copy and edit the production environment file:
```powershell
# Copy the production environment template
copy .env.prod .env.production

# Edit with your preferred text editor (e.g., Notepad++)
notepad .env.production
```

**IMPORTANT: Update these values in .env.production:**
```bash
# Change these passwords!
POSTGRES_PASSWORD=YOUR_SECURE_DB_PASSWORD_HERE
ODOO_ADMIN_PASSWORD=YOUR_SECURE_MASTER_PASSWORD_HERE

# Update your server details
SERVER_IP=192.168.0.21                    # Your server IP
DOMAIN_NAME=your-domain.com                # Your domain name

# Email configuration (for notifications)
ODOO_SMTP_USER=your-email@gmail.com
ODOO_SMTP_PASSWORD=your-app-password
```

#### 1.2 Configure Nginx
Edit the nginx configuration file:
```powershell
# Edit nginx configuration
notepad nginx\nginx.conf
```

**Update these lines in nginx.conf:**
```nginx
# Replace 'your-domain.com' with your actual domain
server_name your-actual-domain.com www.your-actual-domain.com;
```

### Step 2: SSL Certificate Setup

#### Option A: Self-Signed Certificate (Quick Setup)
```powershell
# Run the SSL setup script in PowerShell
bash scripts/ssl-setup.sh
# Choose option 1 for self-signed certificate
```

#### Option B: Let's Encrypt (Linux/WSL only)
```bash
# If using WSL2, you can use Let's Encrypt
export DOMAIN_NAME=your-domain.com
bash scripts/ssl-setup.sh
# Choose option 2 for Let's Encrypt
```

### Step 3: Configure Windows Firewall

Open Windows Firewall and allow these ports:
```powershell
# Run PowerShell as Administrator
New-NetFirewallRule -DisplayName "Odoo HTTP" -Direction Inbound -Protocol TCP -LocalPort 80
New-NetFirewallRule -DisplayName "Odoo HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443
New-NetFirewallRule -DisplayName "Odoo Direct" -Direction Inbound -Protocol TCP -LocalPort 8069
```

### Step 4: Start Production Services

#### 4.1 Build and Start Containers
```powershell
# Build the Odoo container
docker-compose -f docker-compose.prod.yml build

# Start all services
docker-compose -f docker-compose.prod.yml up -d
```

#### 4.2 Monitor Service Status
```powershell
# Check service status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

### Step 5: Initialize Odoo Database

#### 5.1 Access Odoo Web Interface
Open your browser and navigate to:
- **HTTP:** `http://your-server-ip:8069`
- **HTTPS:** `https://your-domain.com` (if SSL configured)

#### 5.2 Create Database
1. Click "Create Database"
2. **Master Password:** Use the one from .env.production
3. **Database Name:** `production` or your preferred name
4. **Email:** Your admin email
5. **Password:** Admin user password
6. **Phone:** Your phone number
7. **Language:** Select your language
8. **Country:** Select your country
9. **Demo Data:** Uncheck for production
10. Click "Create Database"

### Step 6: Production Configuration

#### 6.1 Configure Odoo Settings
1. Go to **Settings > General Settings**
2. Configure:
   - **Company Information**
   - **Email Settings** (use SMTP from .env.production)
   - **Website Settings**
   - **Security Settings**

#### 6.2 Install Required Modules
1. Go to **Apps**
2. Install modules you need:
   - Accounting
   - Sales
   - Inventory
   - Manufacturing
   - HR
   - Website
   - etc.

### Step 7: Backup Configuration

#### 7.1 Test Manual Backup
```powershell
# Run manual backup
docker-compose -f docker-compose.prod.yml exec backup /scripts/backup.sh
```

#### 7.2 Schedule Automatic Backups
Create a Windows Task Scheduler job:
1. Open **Task Scheduler**
2. Create **Basic Task**
3. **Name:** "Odoo Daily Backup"
4. **Trigger:** Daily at 2:00 AM
5. **Action:** Start a program
6. **Program:** `docker-compose`
7. **Arguments:** `-f docker-compose.prod.yml exec backup /scripts/backup.sh`
8. **Start in:** `C:\path\to\your\odoo\directory`

## Daily Operations

### Common Commands

#### Start/Stop Services
```powershell
# Start all services
docker-compose -f docker-compose.prod.yml up -d

# Stop all services
docker-compose -f docker-compose.prod.yml down

# Restart specific service
docker-compose -f docker-compose.prod.yml restart odoo
```

#### View Logs
```powershell
# View all logs
docker-compose -f docker-compose.prod.yml logs

# Follow Odoo logs
docker-compose -f docker-compose.prod.yml logs -f odoo

# View last 100 lines
docker-compose -f docker-compose.prod.yml logs --tail=100 odoo
```

#### Database Operations
```powershell
# Create backup
docker-compose -f docker-compose.prod.yml exec backup /scripts/backup.sh

# List backups
docker-compose -f docker-compose.prod.yml exec backup /scripts/restore.sh -l

# Restore backup
docker-compose -f docker-compose.prod.yml exec backup /scripts/restore.sh backup_file.tar.gz
```

#### Module Management
```powershell
# Install module
docker-compose -f docker-compose.prod.yml exec odoo python3 /opt/odoo/odoo-bin -d production -i module_name

# Update module
docker-compose -f docker-compose.prod.yml exec odoo python3 /opt/odoo/odoo-bin -d production -u module_name

# Update all modules
docker-compose -f docker-compose.prod.yml exec odoo python3 /opt/odoo/odoo-bin -d production -u all
```

### System Maintenance

#### Weekly Tasks
1. **Check disk space:** Ensure adequate space for backups
2. **Review logs:** Check for errors or warnings
3. **Update passwords:** Rotate sensitive passwords
4. **Test backups:** Verify backup integrity

#### Monthly Tasks
1. **Update Docker images:** Pull latest security updates
2. **Review performance:** Monitor resource usage
3. **Security audit:** Check access logs
4. **Backup verification:** Test restore process

## Monitoring and Troubleshooting

### Health Checks
```powershell
# Check container health
docker-compose -f docker-compose.prod.yml ps

# Test Odoo connectivity
curl http://localhost:8069/web/health

# Check database connectivity
docker-compose -f docker-compose.prod.yml exec db pg_isready -U odoo_prod
```

### Performance Monitoring
```powershell
# Monitor resource usage
docker stats

# Check disk usage
docker system df

# View container resource limits
docker-compose -f docker-compose.prod.yml config
```

### Common Issues

#### Issue: "Port already in use"
```powershell
# Find process using port
netstat -ano | findstr :8069

# Kill process (replace PID)
taskkill /PID 1234 /F
```

#### Issue: "Database connection failed"
```powershell
# Check database logs
docker-compose -f docker-compose.prod.yml logs db

# Restart database
docker-compose -f docker-compose.prod.yml restart db
```

#### Issue: "SSL certificate errors"
```powershell
# Check certificate validity
openssl x509 -in nginx/ssl/odoo.crt -text -noout

# Regenerate self-signed certificate
bash scripts/ssl-setup.sh
```

## Security Best Practices

### 1. Change Default Passwords
- Master password in .env.production
- Database passwords
- Admin user passwords

### 2. Enable HTTPS
- Use valid SSL certificates
- Redirect HTTP to HTTPS
- Enable HSTS headers

### 3. Network Security
- Use firewall rules
- Restrict database access
- Monitor access logs

### 4. Regular Updates
- Update Docker images
- Apply security patches
- Monitor security advisories

### 5. Backup Security
- Encrypt backup files
- Store backups off-site
- Test restore procedures

## URLs and Access Points

After successful deployment, access your Odoo instance at:

- **Main Application:** `https://your-domain.com` or `http://your-server-ip:8069`
- **Database Admin:** Access via Odoo interface (Settings > Database)
- **Nginx Status:** `https://your-domain.com/nginx_status` (localhost only)

## Support and Maintenance

For ongoing support:
1. Monitor the logs regularly
2. Keep backups current
3. Update security patches
4. Review performance metrics
5. Document any customizations

## Conclusion

Your Odoo 17 production environment is now ready! Remember to:
- Change all default passwords
- Configure SSL certificates
- Set up monitoring
- Schedule regular backups
- Keep the system updated

For any issues, check the logs first and refer to the troubleshooting section.