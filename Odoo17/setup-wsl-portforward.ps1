# WSL Port Forwarding Setup for Odoo
# Run this PowerShell script as Administrator on Windows
# This forwards traffic from Windows IP to WSL

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "🚀 Setting up WSL Port Forwarding for Odoo..." -ForegroundColor Green

# Get WSL IP dynamically
$wslIP = bash.exe -c "hostname -I | awk '{print `$1}'"
$wslIP = $wslIP.Trim()

# Get Windows IP (WiFi adapter)
$windowsIP = (Get-NetIPAddress -InterfaceAlias "Wi-Fi" -AddressFamily IPv4).IPAddress

Write-Host "📍 Network Configuration:" -ForegroundColor Cyan
Write-Host "   WSL IP: $wslIP" -ForegroundColor White
Write-Host "   Windows IP: $windowsIP" -ForegroundColor White
Write-Host ""

# Remove existing port forwarding rules (if any)
Write-Host "🔄 Removing existing port forwarding rules..." -ForegroundColor Yellow
try {
    netsh interface portproxy delete v4tov4 listenport=80 | Out-Null
    netsh interface portproxy delete v4tov4 listenport=8069 | Out-Null
    Write-Host "   ✅ Existing rules removed" -ForegroundColor Green
} catch {
    Write-Host "   ℹ️ No existing rules to remove" -ForegroundColor Gray
}

# Add new port forwarding rules
Write-Host "➕ Adding port forwarding rules..." -ForegroundColor Yellow

# Forward port 80 (nginx) from Windows to WSL
$result80 = netsh interface portproxy add v4tov4 listenport=80 listenaddress=0.0.0.0 connectport=80 connectaddress=$wslIP
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Port 80 (HTTP/Nginx): Windows → WSL" -ForegroundColor Green
} else {
    Write-Host "   ❌ Failed to set up port 80 forwarding" -ForegroundColor Red
}

# Forward port 8069 (Odoo direct) from Windows to WSL  
$result8069 = netsh interface portproxy add v4tov4 listenport=8069 listenaddress=0.0.0.0 connectport=8069 connectaddress=$wslIP
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ Port 8069 (Odoo Direct): Windows → WSL" -ForegroundColor Green
} else {
    Write-Host "   ❌ Failed to set up port 8069 forwarding" -ForegroundColor Red
}

# Show current port forwarding rules
Write-Host ""
Write-Host "📋 Current Port Forwarding Rules:" -ForegroundColor Cyan
netsh interface portproxy show v4tov4

Write-Host ""
Write-Host "🔥 Windows Firewall Configuration..." -ForegroundColor Yellow

# Add Windows Firewall rules
try {
    # Allow HTTP (port 80)
    New-NetFirewallRule -DisplayName "WSL Odoo HTTP (80)" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow -Profile Any -ErrorAction SilentlyContinue | Out-Null
    Write-Host "   ✅ Firewall rule added for port 80" -ForegroundColor Green
    
    # Allow Odoo (port 8069)
    New-NetFirewallRule -DisplayName "WSL Odoo Direct (8069)" -Direction Inbound -Protocol TCP -LocalPort 8069 -Action Allow -Profile Any -ErrorAction SilentlyContinue | Out-Null
    Write-Host "   ✅ Firewall rule added for port 8069" -ForegroundColor Green
} catch {
    Write-Host "   ⚠️ Firewall rules may already exist or failed to create" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📱 Share these URLs with your friends:" -ForegroundColor Cyan
Write-Host "   Primary (Nginx):  http://$windowsIP" -ForegroundColor White
Write-Host "   Direct (Odoo):    http://${windowsIP}:8069" -ForegroundColor White
Write-Host ""
Write-Host "✨ Benefits:" -ForegroundColor Cyan
Write-Host "   • Clean URLs without port numbers (http://$windowsIP)" -ForegroundColor White
Write-Host "   • Optimized performance with nginx caching" -ForegroundColor White
Write-Host "   • Better security and compression" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Troubleshooting:" -ForegroundColor Yellow
Write-Host "   • Ensure your Odoo server is running in WSL" -ForegroundColor White
Write-Host "   • Use ./start-with-nginx.sh in your Odoo directory" -ForegroundColor White
Write-Host "   • Check Windows Defender isn't blocking connections" -ForegroundColor White
Write-Host ""
Write-Host "To remove these rules later, run: setup-wsl-portforward-remove.ps1" -ForegroundColor Gray

Read-Host "Press Enter to close"