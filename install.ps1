<#
.SYNOPSIS
    Installs Network Doctor and makes it easy to launch from anywhere.

.DESCRIPTION
    This is the recommended way to install Network Doctor.
    It will:
      - Copy the tool to your user Tools folder
      - Create a 'network-doctor' command you can run from anywhere
      - Add the folder to your PATH (so you can just type network-doctor)
#>

[CmdletBinding()]
param(
    [string]$InstallPath = "$env:USERPROFILE\Tools",
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

Write-Host "`n=== Network Doctor Installer ===" -ForegroundColor Cyan
Write-Host "Version: 0.2.0`n" -ForegroundColor DarkGray

# Create Tools folder if it doesn't exist
if (!(Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    Write-Host "Created: $InstallPath" -ForegroundColor Green
}

# Copy main script
$source = Join-Path $PSScriptRoot "src\AdvancedNetworkMonitor.ps1"
$target = Join-Path $InstallPath "NetworkDoctor.ps1"

if (!(Test-Path $source)) {
    Write-Error "Could not find the main script. Please run this from the repository root."
}

Copy-Item $source $target -Force
Write-Host "Installed script → $target" -ForegroundColor Green

# Create the command shim (this is what lets you type 'network-doctor')
$shim = Join-Path $InstallPath "network-doctor.cmd"
$shimContent = @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\Tools\NetworkDoctor.ps1" %*
"@
$shimContent | Out-File -FilePath $shim -Encoding ASCII -Force
Write-Host "Created command  → network-doctor" -ForegroundColor Green

# Automatically add to PATH if not already there (with clear feedback)
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$InstallPath*") {
    Write-Host ""
    Write-Host "Adding $InstallPath to your PATH..." -ForegroundColor Yellow
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$InstallPath", "User")
    Write-Host "Done! You will need to restart your terminal for this to take effect." -ForegroundColor Green
} else {
    Write-Host "$InstallPath is already in your PATH." -ForegroundColor DarkGray
}

# Friendly execution policy check
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -eq 'Restricted') {
    Write-Host ""
    Write-Warning "Your execution policy is currently Restricted."
    $answer = Read-Host "Would you like to change it to RemoteSigned so the tool can run? (yes/no)"
    if ($answer -eq 'yes') {
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Host "Execution policy updated to RemoteSigned." -ForegroundColor Green
        } catch {
            Write-Host "Could not change policy automatically. You may need to run this as Administrator once." -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "You can now open a new terminal and simply type:" -ForegroundColor Cyan
Write-Host "    network-doctor" -ForegroundColor White
Write-Host ""
Write-Host "Tip: Restart your terminal / VS Code for PATH changes to apply." -ForegroundColor Yellow
