"""
LDAP Compatibility Layer for Windows Odoo 17
Provides python-ldap compatible interface using ldap3 backend

This module allows Odoo to work with LDAP on Windows by providing
a compatibility layer that translates python-ldap calls to ldap3.
"""

import sys
import logging

try:
    import ldap3
    from ldap3 import Server, Connection, ALL, SUBTREE, BASE, LEVEL
    from ldap3.core.exceptions import LDAPException
    LDAP3_AVAILABLE = True
except ImportError:
    LDAP3_AVAILABLE = False

# Logging setup
logger = logging.getLogger(__name__)

class LDAPError(Exception):
    """Base LDAP exception compatible with python-ldap"""
    pass

class LDAPCompat:
    """
    Compatibility layer that provides python-ldap interface using ldap3
    """
    
    # LDAP scope constants (python-ldap compatible)
    SCOPE_BASE = 0
    SCOPE_ONELEVEL = 1  
    SCOPE_SUBTREE = 2
    
    # LDAP protocol constants
    VERSION3 = 3
    
    def __init__(self):
        if not LDAP3_AVAILABLE:
            raise ImportError("ldap3 is required for Windows LDAP support")
            
    def initialize(self, uri):
        """Initialize LDAP connection (python-ldap compatible)"""
        logger.debug(f"Initializing LDAP connection to {uri}")
        return LDAPConnectionCompat(uri)
    
    def open(self, host, port=389):
        """Open LDAP connection (python-ldap compatible)"""
        uri = f"ldap://{host}:{port}"
        return self.initialize(uri)

class LDAPConnectionCompat:
    """
    LDAP Connection compatibility layer
    """
    
    def __init__(self, uri):
        self.uri = uri
        self.connection = None
        self.server = None
        
    def simple_bind_s(self, who=None, cred=None):
        """Simple bind (python-ldap compatible)"""
        try:
            # Parse server from URI
            if self.uri.startswith('ldap://'):
                host = self.uri.replace('ldap://', '').split(':')[0]
            else:
                host = self.uri
                
            self.server = Server(host, get_info=ALL)
            self.connection = Connection(
                self.server, 
                user=who, 
                password=cred,
                auto_bind=True
            )
            return (97, [], 1, [])  # python-ldap success format
            
        except Exception as e:
            logger.error(f"LDAP bind failed: {e}")
            raise LDAPError(f"Bind failed: {e}")
    
    def search_s(self, base, scope, filterstr='(objectClass=*)', attrlist=None):
        """Search LDAP (python-ldap compatible)"""
        try:
            if not self.connection:
                raise LDAPError("Not connected")
                
            # Convert scope
            ldap3_scope = SUBTREE
            if scope == 0:  # SCOPE_BASE
                ldap3_scope = BASE
            elif scope == 1:  # SCOPE_ONELEVEL  
                ldap3_scope = LEVEL
            elif scope == 2:  # SCOPE_SUBTREE
                ldap3_scope = SUBTREE
                
            # Perform search
            self.connection.search(
                search_base=base,
                search_filter=filterstr,
                search_scope=ldap3_scope,
                attributes=attrlist or []
            )
            
            # Convert results to python-ldap format
            results = []
            for entry in self.connection.entries:
                dn = str(entry.entry_dn)
                attrs = {}
                for attr_name in entry.entry_attributes:
                    attrs[attr_name] = entry[attr_name].values
                results.append((dn, attrs))
                
            return results
            
        except Exception as e:
            logger.error(f"LDAP search failed: {e}")
            raise LDAPError(f"Search failed: {e}")
    
    def unbind_s(self):
        """Unbind connection (python-ldap compatible)"""
        if self.connection:
            self.connection.unbind()
            self.connection = None

def install_ldap_compatibility():
    """
    Install LDAP compatibility layer in sys.modules
    This allows 'import ldap' to work using ldap3 backend
    """
    if 'ldap' in sys.modules:
        logger.debug("LDAP module already in sys.modules")
        return True
        
    if not LDAP3_AVAILABLE:
        logger.error("ldap3 not available - cannot provide LDAP compatibility")
        return False
    
    try:
        # Create compatibility module
        compat = LDAPCompat()
        
        # Add module-level functions and constants
        compat.LDAPError = LDAPError
        compat.SCOPE_BASE = LDAPCompat.SCOPE_BASE
        compat.SCOPE_ONELEVEL = LDAPCompat.SCOPE_ONELEVEL  
        compat.SCOPE_SUBTREE = LDAPCompat.SCOPE_SUBTREE
        compat.VERSION3 = LDAPCompat.VERSION3
        
        # Install in sys.modules
        sys.modules['ldap'] = compat
        
        logger.info("LDAP compatibility layer installed successfully")
        return True
        
    except Exception as e:
        logger.error(f"Failed to install LDAP compatibility: {e}")
        return False

# Auto-install compatibility layer when module is imported
if __name__ != "__main__":
    try:
        install_ldap_compatibility()
    except Exception:
        # Silently fail if LDAP compatibility can't be installed
        # This ensures the module import doesn't break Odoo startup
        pass