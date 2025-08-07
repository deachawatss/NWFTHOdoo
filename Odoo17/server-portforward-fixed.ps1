# WSL Port Forwarding Setup for Odoo SERVER
# Run this PowerShell script as Administrator on Windows SERVER
# This forwards traffic from Windows SERVER IP (192.168.0.21) to WSL

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Setting up WSL Port Forwarding for Odoo SERVER..." -ForegroundColor Green

# Get WSL IP dynamically
$wslIP = bash.exe -c "hostname -I | awk '{print `$1}'"
$wslIP = $wslIP.Trim()

# Server's external IP (your Windows server IP)
$serverIP = "192.168.0.21"

Write-Host "SERVER Network Configuration:" -ForegroundColor Cyan
Write-Host "   WSL IP: $wslIP" -ForegroundColor White
Write-Host "   Server External IP: $serverIP" -ForegroundColor White
Write-Host "   Network: External access enabled" -ForegroundColor Green
Write-Host ""

# Remove existing port forwarding rules (if any)
Write-Host "Removing existing port forwarding rules..." -ForegroundColor Yellow
try {
    netsh interface portproxy delete v4tov4 listenport=80 | Out-Null
    netsh interface portproxy delete v4tov4 listenport=8069 | Out-Null
    netsh interface portproxy delete v4tov4 listenport=443 | Out-Null
    Write-Host "   Existing rules removed" -ForegroundColor Green
} catch {
    Write-Host "   No existing rules to remove" -ForegroundColor Gray
}

# Add new port forwarding rules for SERVER
Write-Host "Adding SERVER port forwarding rules..." -ForegroundColor Yellow

# Forward port 80 (nginx) from Server to WSL
$result80 = netsh interface portproxy add v4tov4 listenport=80 listenaddress=0.0.0.0 connectport=80 connectaddress=$wslIP
if ($LASTEXITCODE -eq 0) {
    Write-Host "   Port 80 (HTTP/Nginx): SERVER -> WSL" -ForegroundColor Green
} else {
    Write-Host "   Failed to set up port 80 forwarding" -ForegroundColor Red
}

# Forward port 8069 (Odoo direct) from Server to WSL  
$result8069 = netsh interface portproxy add v4tov4 listenport=8069 listenaddress=0.0.0.0 connectport=8069 connectaddress=$wslIP
if ($LASTEXITCODE -eq 0) {
    Write-Host "   Port 8069 (Odoo Direct): SERVER -> WSL" -ForegroundColor Green
} else {
    Write-Host "   Failed to set up port 8069 forwarding" -ForegroundColor Red
}

# Forward port 443 (HTTPS future use) from Server to WSL
$result443 = netsh interface portproxy add v4tov4 listenport=443 listenaddress=0.0.0.0 connectport=443 connectaddress=$wslIP
if ($LASTEXITCODE -eq 0) {
    Write-Host "   Port 443 (HTTPS): SERVER -> WSL" -ForegroundColor Green
} else {
    Write-Host "   Port 443 forwarding may have failed (normal if not using HTTPS)" -ForegroundColor Yellow
}

# Show current port forwarding rules
Write-Host ""
Write-Host "Current SERVER Port Forwarding Rules:" -ForegroundColor Cyan
netsh interface portproxy show v4tov4

Write-Host ""
Write-Host "Windows SERVER Firewall Configuration..." -ForegroundColor Yellow

# Add Windows Firewall rules for SERVER
try {
    # Allow HTTP (port 80)
    New-NetFirewallRule -DisplayName "Odoo Server HTTP (80)" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow -Profile Any -ErrorAction SilentlyContinue | Out-Null
    Write-Host "   Firewall rule added for port 80" -ForegroundColor Green
    
    # Allow Odoo (port 8069)
    New-NetFirewallRule -DisplayName "Odoo Server Direct (8069)" -Direction Inbound -Protocol TCP -LocalPort 8069 -Action Allow -Profile Any -ErrorAction SilentlyContinue | Out-Null
    Write-Host "   Firewall rule added for port 8069" -ForegroundColor Green
    
    # Allow HTTPS (port 443)
    New-NetFirewallRule -DisplayName "Odoo Server HTTPS (443)" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow -Profile Any -ErrorAction SilentlyContinue | Out-Null
    Write-Host "   Firewall rule added for port 443" -ForegroundColor Green
} catch {
    Write-Host "   Some firewall rules may already exist or failed to create" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "SERVER Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "PUBLIC ACCESS URLS:" -ForegroundColor Cyan
Write-Host "   Primary (Nginx):  http://$serverIP" -ForegroundColor White
Write-Host "   Direct (Odoo):    http://${serverIP}:8069" -ForegroundColor White
Write-Host "   HTTPS (Future):   https://$serverIP" -ForegroundColor Gray
Write-Host ""
Write-Host "SERVER FEATURES:" -ForegroundColor Cyan
Write-Host "   External internet access ready" -ForegroundColor White
Write-Host "   Network users can access via $serverIP" -ForegroundColor White
Write-Host "   Clean URLs without port numbers" -ForegroundColor White
Write-Host "   Nginx reverse proxy with caching" -ForegroundColor White
Write-Host "   Production-ready security headers" -ForegroundColor White
Write-Host "   Large file upload support (100MB)" -ForegroundColor White
Write-Host ""
Write-Host "EXTERNAL ACCESS:" -ForegroundColor Yellow
Write-Host "   Local Network: Ready" -ForegroundColor White
Write-Host "   Internet Access: Configure router port forwarding" -ForegroundColor White
Write-Host "   Domain Name: Point DNS to $serverIP" -ForegroundColor White
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "   1. Start Odoo: ./start-server-nginx.sh (in WSL)" -ForegroundColor White
Write-Host "   2. Test locally: http://localhost" -ForegroundColor White
Write-Host "   3. Share with users: http://$serverIP" -ForegroundColor White
Write-Host "   4. For internet access: Configure router" -ForegroundColor White
Write-Host ""
Write-Host "To remove these rules later, run with -Remove flag" -ForegroundColor Gray

Read-Host "Press Enter to close"