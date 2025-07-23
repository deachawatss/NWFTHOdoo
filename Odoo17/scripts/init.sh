#!/bin/bash
# Odoo initialization script
# This script handles initialization tasks for the Odoo container

echo "Initializing Odoo container..."

# Set proper permissions if needed
chown -R odoo:odoo /var/lib/odoo || true
chown -R odoo:odoo /var/log/odoo || true

echo "Odoo container initialization completed."