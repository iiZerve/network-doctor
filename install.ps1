<#
.SYNOPSIS
    Installs Network Doctor and makes it easy to run from anywhere.

.DESCRIPTION
    This installer:
    - Copies the tool to your Tools folder
    - Creates a simple 'network-doctor' command (shim)
    - Optionally adds the Tools folder to your PATH
    - Handles execution policy issues gracefully
#>

[CmdletBinding()]
param(
    [string]$InstallPath = "$env:USERPROFILE\Tools",
    [switch]$AddToPath,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

Write-Host "`n=== Network Doctor Installer ===" -ForegroundColor Cyan

# --- 1. Create install directory ---
if (!(Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    Write-Host "Created folder: $InstallPath" -ForegroundColor Green
}

# --- 2. Copy the main script ---
$sourceScript = Join-Path $PSScriptRoot "src\AdvancedNetworkMonitor.ps1"
$targetScript = Join-Path $InstallPath "NetworkDoctor.ps1"

if (!(Test-Path $sourceScript)) {
    Write-Error "Could not find the main script. Make sure you're running install.ps1 from the repository root."
}

Copy-Item $sourceScript $targetScript -Force
Write-Host "Installed script to: $targetScript" -ForegroundColor Green

# --- 3. Create a simple .cmd shim (this is the magic for easy launching) ---
$shimPath = Join-Path $InstallPath "network-doctor.cmd"
$shimContent = @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\Tools\NetworkDoctor.ps1" %*
"@

$shimContent | Out-File -FilePath $shimPath -Encoding ASCII -Force
Write-Host "Created command: network-doctor.cmd" -ForegroundColor Green

# --- 4. Handle PATH ---
$toolsInPath = $env:Path -split ';' | Where-Object { $_ -eq $InstallPath }

if (-not $toolsInPath -and -not $AddToPath) {
    Write-Host ""
    $response = Read-Host "Add $InstallPath to your PATH so you can just type 'network-doctor'? (yes/no)"
    if ($response -eq 'yes') {
        $AddToPath = $true
    }
}

if ($AddToPath) {
    $currentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentUserPath -notlike "*$InstallPath*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentUserPath;$InstallPath", "User")
        Write-Host "Added $InstallPath to your user PATH." -ForegroundColor Green
        Write-Host "You will need to restart your terminal / VS Code for this to take effect." -ForegroundColor Yellow
    } else {
        Write-Host "$InstallPath is already in your PATH." -ForegroundColor Yellow
    }
}

# --- 5. Execution Policy Check (helpful) ---
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -eq 'Restricted') {
    Write-Host ""
    Write-Warning "Your CurrentUser execution policy is set to Restricted."
    $fixPolicy = Read-Host "Would you like to set it to RemoteSigned so scripts can run? (yes/no)"
    if ($fixPolicy -eq 'yes') {
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Host "Execution policy set to RemoteSigned for CurrentUser." -ForegroundColor Green
        } catch {
            Write-Host "Failed to change execution policy. You may need to run this as Administrator or do it manually." -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "You can now run the tool by typing:" -ForegroundColor Cyan
Write-Host "    network-doctor" -ForegroundColor White
Write-Host ""
Write-Host "Note: If you just added the folder to PATH, restart your terminal first." -ForegroundColor Yellow
