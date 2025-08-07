# Simple WSL Port Forwarding for Odoo SERVER
# Run this PowerShell script as Administrator on Windows SERVER
# This forwards traffic from Windows SERVER IP (192.168.0.21:8069) to WSL

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Setting up Simple WSL Port Forwarding for Odoo..." -ForegroundColor Green

# Get WSL IP dynamically
$wslIP = bash.exe -c "hostname -I | awk '{print `$1}'"
$wslIP = $wslIP.Trim()

# Server's external IP
$serverIP = "192.168.0.21"

Write-Host "Network Configuration:" -ForegroundColor Cyan
Write-Host "   WSL IP: $wslIP" -ForegroundColor White
Write-Host "   Server IP: $serverIP" -ForegroundColor White
Write-Host ""

# Remove existing port forwarding rules
Write-Host "Removing existing port forwarding rules..." -ForegroundColor Yellow
try {
    netsh interface portproxy delete v4tov4 listenport=8069 | Out-Null
    Write-Host "   Existing rules removed" -ForegroundColor Green
} catch {
    Write-Host "   No existing rules to remove" -ForegroundColor Gray
}

# Add port forwarding for Odoo (port 8069)
Write-Host "Adding port forwarding rule..." -ForegroundColor Yellow
$result = netsh interface portproxy add v4tov4 listenport=8069 listenaddress=0.0.0.0 connectport=8069 connectaddress=$wslIP

if ($LASTEXITCODE -eq 0) {
    Write-Host "   Port 8069: SUCCESS - $serverIP:8069 -> WSL:8069" -ForegroundColor Green
} else {
    Write-Host "   Port 8069: FAILED to set up forwarding" -ForegroundColor Red
}

# Show current rules
Write-Host ""
Write-Host "Current Port Forwarding Rules:" -ForegroundColor Cyan
netsh interface portproxy show v4tov4

# Add Windows Firewall rule
Write-Host ""
Write-Host "Configuring Windows Firewall..." -ForegroundColor Yellow
try {
    New-NetFirewallRule -DisplayName "Odoo Server (8069)" -Direction Inbound -Protocol TCP -LocalPort 8069 -Action Allow -Profile Any -ErrorAction SilentlyContinue | Out-Null
    Write-Host "   Firewall rule added for port 8069" -ForegroundColor Green
} catch {
    Write-Host "   Firewall rule may already exist" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "ACCESS URL:" -ForegroundColor Cyan
Write-Host "   Share this: http://$serverIP:8069" -ForegroundColor White
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "   1. Start Odoo in WSL: ./start-dev.sh" -ForegroundColor White
Write-Host "   2. Test: http://localhost:8069" -ForegroundColor White
Write-Host "   3. Share: http://$serverIP:8069" -ForegroundColor White

Read-Host "Press Enter to close"