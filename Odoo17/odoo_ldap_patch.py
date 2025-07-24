#!/usr/bin/env python3
"""
Odoo LDAP Startup Patch for Windows
Ensures LDAP compatibility is loaded before any Odoo modules
"""

import sys
import os

# Add current directory to Python path
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

# Load LDAP compatibility before any imports
try:
    import ldap_compat
    print("✓ LDAP compatibility loaded successfully")
except Exception as e:
    print(f"✗ Failed to load LDAP compatibility: {e}")
    print("Please ensure ldap3 is installed: pip install ldap3")

# Test LDAP import
try:
    import ldap
    print("✓ LDAP module available")
except ImportError as e:
    print(f"✗ LDAP module still not available: {e}")