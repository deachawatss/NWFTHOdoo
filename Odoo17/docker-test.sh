#!/bin/bash
# Test script for Docker fixes

echo "Testing Docker Odoo 17 Configuration..."

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not available. Please ensure Docker Desktop is installed and WSL integration is enabled."
    exit 1
fi

# Navigate to project directory
cd "$(dirname "$0")"

echo "Building main Odoo container..."
docker-compose build --no-cache odoo

echo "Building backup container..."
docker-compose build --no-cache backup

echo "Starting services..."
docker-compose up -d db

# Wait for database to be ready
echo "Waiting for database to be ready..."
sleep 30

echo "Starting Odoo service..."
docker-compose up -d odoo

# Check if container started successfully
echo "Checking container status..."
docker-compose ps

echo "Checking container logs for errors..."
docker-compose logs odoo --tail=50

echo "Testing backup service..."
docker-compose --profile backup run --rm backup

echo "Test completed. Check output above for any errors."