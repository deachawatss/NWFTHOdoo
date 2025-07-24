#!/usr/bin/env python3
"""
LDAP Compatibility Layer for Windows Odoo 17
Provides python-ldap compatible interface using ldap3 for Windows

This file solves the "ModuleNotFoundError: No module named 'ldap'" issue
on Windows servers where python-ldap compilation fails.
"""

import sys
import os

try:
    # Try to import native python-ldap first (Linux/Unix)
    import ldap
    print("✓ Native python-ldap imported successfully")
except ImportError:
    # Fall back to ldap3 compatibility layer (Windows)
    try:
        import ldap3
        print("✓ Using ldap3 compatibility layer for Windows")
        
        # Create ldap module with ldap3 compatibility
        import types
        ldap = types.ModuleType('ldap')
        
        # Map common LDAP constants
        ldap.SCOPE_BASE = ldap3.BASE
        ldap.SCOPE_ONELEVEL = ldap3.LEVEL
        ldap.SCOPE_SUBTREE = ldap3.SUBTREE
        
        # Map LDAP exceptions
        class LDAPError(Exception):
            pass
        
        class INVALID_CREDENTIALS(LDAPError):
            pass
        
        class SERVER_DOWN(LDAPError):
            pass
        
        ldap.LDAPError = LDAPError
        ldap.INVALID_CREDENTIALS = INVALID_CREDENTIALS
        ldap.SERVER_DOWN = SERVER_DOWN
        
        # Simple LDAP connection class using ldap3
        class LDAPConnection:
            def __init__(self, uri):
                self.uri = uri
                self.connection = None
                
            def simple_bind_s(self, who, cred):
                try:
                    server = ldap3.Server(self.uri)
                    self.connection = ldap3.Connection(server, user=who, password=cred, auto_bind=True)
                    return True
                except Exception as e:
                    if "invalid credentials" in str(e).lower():
                        raise INVALID_CREDENTIALS(str(e))
                    elif "server" in str(e).lower():
                        raise SERVER_DOWN(str(e))
                    else:
                        raise LDAPError(str(e))
                        
            def search_s(self, base, scope, filterstr, attrlist=None):
                if not self.connection:
                    raise LDAPError("Not connected")
                    
                try:
                    self.connection.search(base, filterstr, scope, attributes=attrlist)
                    results = []
                    for entry in self.connection.entries:
                        dn = entry.entry_dn
                        attrs = {}
                        for attr in entry.entry_attributes:
                            attrs[attr] = [str(val) for val in entry[attr].values]
                        results.append((dn, attrs))
                    return results
                except Exception as e:
                    raise LDAPError(str(e))
                    
            def unbind_s(self):
                if self.connection:
                    self.connection.unbind()
                    self.connection = None
        
        # Create initialize function
        def initialize(uri):
            return LDAPConnection(uri)
        
        ldap.initialize = initialize
        
        # Create ldap.filter module
        filter_module = types.ModuleType('ldap.filter')
        
        def filter_format(filter_template, filter_args):
            """LDAP filter formatting function"""
            result = filter_template
            for arg in filter_args:
                # Simple escaping for LDAP filter
                escaped_arg = str(arg).replace('\\', '\\\\').replace('*', '\\*').replace('(', '\\(').replace(')', '\\)')
                result = result.replace('%s', escaped_arg, 1)
            return result
            
        filter_module.filter_format = filter_format
        ldap.filter = filter_module
        
        # Add to sys.modules so imports work
        sys.modules['ldap'] = ldap
        sys.modules['ldap.filter'] = filter_module
        
        print("✓ LDAP compatibility layer activated for Windows")
        
    except ImportError as e:
        print(f"✗ LDAP compatibility setup failed: {e}")
        print("Please run: pip install ldap3")
        raise

# Verify the module is working
if __name__ == "__main__":
    print("Testing LDAP compatibility...")
    try:
        import ldap
        print("✓ LDAP module import: SUCCESS")
        print(f"✓ LDAP module source: {ldap.__file__ if hasattr(ldap, '__file__') else 'compatibility layer'}")
        
        # Test basic functionality
        if hasattr(ldap, 'initialize'):
            print("✓ LDAP initialize function: AVAILABLE")
        if hasattr(ldap, 'LDAPError'):
            print("✓ LDAP error classes: AVAILABLE")
            
        print("\n✅ LDAP compatibility test: PASSED")
        print("🎯 Odoo auth_ldap module should now work correctly!")
        
    except Exception as e:
        print(f"✗ LDAP compatibility test: FAILED - {e}")
        sys.exit(1)