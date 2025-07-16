# Odoo 17 Admin Password Configuration Guide

## Current Configuration

### **Default Admin Password**
- **Password**: `AdminSecure2024!`
- **Location**: Set in `odoo.conf` file
- **Purpose**: Master password for database management operations

## How to Use Admin Password

### **1. Database Management**
When accessing database operations, use this password:
- Creating new databases
- Dropping databases
- Duplicating databases
- Backing up databases

### **2. Accessing Database Manager**
1. Go to: `http://192.168.0.21:8069/web/database/manager`
2. Enter the admin password: `AdminSecure2024!`
3. You can now create, backup, restore, or delete databases

### **3. Initial Database Creation**
1. Navigate to: `http://192.168.0.21:8069`
2. If no database exists, you'll see the database creation form
3. Enter admin password: `AdminSecure2024!`
4. Create your first database

## How to Change Admin Password

### **Method 1: Update odoo.conf (Recommended)**
1. Edit `/home/deachawat/dev/projects/Odoo/Odoo17/odoo.conf`
2. Change line: `admin_passwd = AdminSecure2024!`
3. To new password: `admin_passwd = YourNewPassword`
4. Restart containers: `docker-compose restart`

### **Method 2: Environment Variable**
1. Edit `docker-compose.yml`
2. Add to odoo service environment:
   ```yaml
   environment:
     - ADMIN_PASSWD=YourNewPassword
   ```
3. Restart containers: `docker-compose restart`

### **Method 3: Hash the Password (Most Secure)**
1. Generate password hash:
   ```bash
   python3 -c "
   import hashlib
   import base64
   import os
   password = 'YourNewPassword'
   salt = os.urandom(16)
   key = hashlib.pbkdf2_hmac('sha512', password.encode(), salt, 600000)
   hash_value = base64.b64encode(salt + key).decode()
   print(f'$pbkdf2-sha512$600000${hash_value}')
   "
   ```
2. Update odoo.conf with the generated hash
3. Restart containers

## Security Best Practices

### **Production Environment**
- ✅ Use a strong, unique admin password
- ✅ Consider hashing the password
- ✅ Restrict database manager access in production
- ✅ Use environment variables for sensitive data

### **Security Settings in odoo.conf**
```ini
# Disable database manager in production
list_db = False

# Enable proxy mode
proxy_mode = True

# Limit database operations
db_name = your_database_name
```

## Database User vs Admin Password

### **Database User (odoo_prod)**
- **Purpose**: Database connection authentication
- **Password**: `OdooSecure2024!`
- **Used for**: PostgreSQL database access

### **Admin Password (AdminSecure2024!)**
- **Purpose**: Odoo database management operations
- **Used for**: Creating/managing databases through Odoo interface

## Troubleshooting

### **"Access Denied" Error**
- Check if admin password is correct
- Verify `list_db = False` is not set if you need database access
- Ensure no typos in password

### **Database Connection Issues**
- This is different from admin password issues
- Check database user credentials in docker-compose.yml
- Verify database container is running

### **Reset Admin Password**
1. Stop containers: `docker-compose down`
2. Edit odoo.conf with new password
3. Start containers: `docker-compose up -d`

## Quick Reference

| Purpose | Username | Password |
|---------|----------|----------|
| Database Management | N/A | `AdminSecure2024!` |
| Database Connection | `odoo_prod` | `OdooSecure2024!` |
| First User Login | Create during setup | Set during database creation |

## Production Deployment

For production use:
1. Change default admin password immediately
2. Use environment variables for passwords
3. Set `list_db = False` in odoo.conf
4. Enable proper firewall rules
5. Use SSL/TLS certificates