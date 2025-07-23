#!/bin/bash

echo "🔍 Validating Docker Production Configuration..."
echo "================================================"

# Check if required files exist
echo "📁 Checking required files..."
files=("docker-compose.yml" "odoo.conf" ".env.prod" "docker-entrypoint.sh" "Dockerfile" "CLAUDE.md")
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done

echo ""
echo "🔑 Checking credentials in docker-compose.yml..."
if grep -q "POSTGRES_USER=admin" docker-compose.yml && grep -q "POSTGRES_PASSWORD=1234" docker-compose.yml; then
    echo "✅ PostgreSQL credentials: admin/1234"
else
    echo "❌ PostgreSQL credentials not found"
fi

if grep -q "192.168.0.21:8069" docker-compose.yml; then
    echo "✅ Network binding: 192.168.0.21:8069"
else
    echo "❌ Network binding not configured"
fi

echo ""
echo "🔑 Checking credentials in odoo.conf..."
if grep -q "admin_passwd = 1234" odoo.conf && grep -q "db_user = admin" odoo.conf && grep -q "db_password = 1234" odoo.conf; then
    echo "✅ Odoo credentials: admin/1234"
else
    echo "❌ Odoo credentials not configured"
fi

if grep -q "list_db = True" odoo.conf; then
    echo "✅ Database management enabled"
else
    echo "❌ Database management not enabled"
fi

echo ""
echo "🔑 Checking environment file..."
if grep -q "POSTGRES_USER=admin" .env.prod && grep -q "POSTGRES_PASSWORD=1234" .env.prod; then
    echo "✅ Environment variables: admin/1234"
else
    echo "❌ Environment variables not configured"
fi

echo ""
echo "🧹 Checking cleanup..."
if [ ! -f "*.bat" ] && [ ! -f "odoo-windows.conf" ]; then
    echo "✅ Windows files removed"
else
    echo "❌ Windows files still present"
fi

# Check if unnecessary .md files are removed
md_count=$(find . -name "*.md" -not -name "CLAUDE.md" -not -path "./odoo_env/*" -not -path "./custom_addons/*/readme/*" -type f | wc -l)
if [ "$md_count" -eq 0 ]; then
    echo "✅ Unnecessary .md files removed"
else
    echo "❌ $md_count unnecessary .md files still present"
fi

echo ""
echo "📋 Configuration Summary:"
echo "========================"
echo "🎯 Server IP: 192.168.0.21"
echo "🔑 Master Password: 1234"
echo "🗄️  PostgreSQL: admin/1234"
echo "🌐 Web Interface: http://192.168.0.21:8069"
echo "📊 Database Manager: /web/database/manager"
echo "🔧 Database Management: Enabled"

echo ""
echo "🚀 Ready for Docker production deployment!"
echo "Run: docker-compose up -d"