#!/bin/bash
# Odoo healthcheck script
# This script performs basic health checks for the Odoo container

# Check if Odoo is running on port 8069
curl -f http://localhost:8069/ || curl -f http://localhost:8069/web/health || wget --no-verbose --tries=1 --spider http://localhost:8069/ || exit 1