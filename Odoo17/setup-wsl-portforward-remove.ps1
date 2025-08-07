# Remove WSL Port Forwarding Rules
# Run this PowerShell script as Administrator on Windows

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "🗑️ Removing WSL Port Forwarding Rules..." -ForegroundColor Yellow

# Remove port forwarding rules
netsh interface portproxy delete v4tov4 listenport=80
netsh interface portproxy delete v4tov4 listenport=8069

# Remove firewall rules
Remove-NetFirewallRule -DisplayName "WSL Odoo HTTP (80)" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName "WSL Odoo Direct (8069)" -ErrorAction SilentlyContinue

Write-Host "✅ Port forwarding rules removed" -ForegroundColor Green

# Show remaining rules
Write-Host ""
Write-Host "📋 Remaining Port Forwarding Rules:" -ForegroundColor Cyan
netsh interface portproxy show v4tov4

Read-Host "Press Enter to close"