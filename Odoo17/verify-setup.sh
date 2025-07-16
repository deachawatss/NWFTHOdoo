#!/bin/bash
# Verify Docker setup before building

echo "=== Verifying Odoo Docker Setup ==="

# Check if required files exist
echo "1. Checking required files..."

if [ -f "docker-entrypoint.sh" ]; then
    echo "✅ docker-entrypoint.sh exists"
    if [ -x "docker-entrypoint.sh" ]; then
        echo "✅ docker-entrypoint.sh is executable"
    else
        echo "❌ docker-entrypoint.sh is not executable"
        chmod +x docker-entrypoint.sh
        echo "✅ Fixed docker-entrypoint.sh permissions"
    fi
else
    echo "❌ docker-entrypoint.sh missing"
fi

if [ -d "scripts" ]; then
    echo "✅ scripts directory exists"
    if [ -f "scripts/backup.sh" ]; then
        echo "✅ scripts/backup.sh exists"
        if [ -x "scripts/backup.sh" ]; then
            echo "✅ scripts/backup.sh is executable"
        else
            echo "❌ scripts/backup.sh is not executable"
            chmod +x scripts/backup.sh
            echo "✅ Fixed scripts/backup.sh permissions"
        fi
    else
        echo "❌ scripts/backup.sh missing"
    fi
    
    if [ -f "scripts/restore.sh" ]; then
        echo "✅ scripts/restore.sh exists"
        if [ -x "scripts/restore.sh" ]; then
            echo "✅ scripts/restore.sh is executable"
        else
            echo "❌ scripts/restore.sh is not executable"
            chmod +x scripts/restore.sh
            echo "✅ Fixed scripts/restore.sh permissions"
        fi
    else
        echo "❌ scripts/restore.sh missing"
    fi
else
    echo "❌ scripts directory missing"
fi

# Check Docker files
echo ""
echo "2. Checking Docker configuration..."

if [ -f "Dockerfile" ]; then
    echo "✅ Dockerfile exists"
else
    echo "❌ Dockerfile missing"
fi

if [ -f "Dockerfile.backup" ]; then
    echo "✅ Dockerfile.backup exists"
else
    echo "❌ Dockerfile.backup missing"
fi

if [ -f "docker-compose.yml" ]; then
    echo "✅ docker-compose.yml exists"
else
    echo "❌ docker-compose.yml missing"
fi

echo ""
echo "3. File permissions summary:"
ls -la docker-entrypoint.sh 2>/dev/null || echo "docker-entrypoint.sh not found"
ls -la scripts/ 2>/dev/null || echo "scripts directory not found"

echo ""
echo "=== Setup verification complete ==="