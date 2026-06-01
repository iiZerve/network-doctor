<#
.SYNOPSIS
    Installs Network Doctor for easy use.
#>

[CmdletBinding()]
param(
    [string]$InstallPath = "$env:USERPROFILE\Tools",
    [switch]$AddToPath,
    [switch]$CreateAlias
)

$ErrorActionPreference = "Stop"

Write-Host "Installing Network Doctor..." -ForegroundColor Cyan

if (!(Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    Write-Host "Created directory: $InstallPath" -ForegroundColor Green
}

$source = Join-Path $PSScriptRoot "src\AdvancedNetworkMonitor.ps1"
$destination = Join-Path $InstallPath "NetworkDoctor.ps1"

if (!(Test-Path $source)) {
    Write-Error "Could not find source script at: $source"
    exit 1
}

Copy-Item -Path $source -Destination $destination -Force
Write-Host "Installed to: $destination" -ForegroundColor Green

if ($AddToPath) {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$InstallPath*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$InstallPath", "User")
        Write-Host "Added $InstallPath to your user PATH." -ForegroundColor Green
        Write-Host "Please restart your terminal for the change to take effect." -ForegroundColor Yellow
    } else {
        Write-Host "$InstallPath is already in your PATH." -ForegroundColor Yellow
    }
}

if ($CreateAlias) {
    $profilePath = $PROFILE.CurrentUserAllHosts
    if (!(Test-Path $profilePath)) {
        New-Item -ItemType File -Path $profilePath -Force | Out-Null
    }

    $aliasLine = 'function network-doctor { & "$env:USERPROFILE\Tools\NetworkDoctor.ps1" @args }'

    if ((Get-Content $profilePath -Raw) -notmatch "function network-doctor") {
        Add-Content -Path $profilePath -Value "`n$aliasLine"
        Write-Host "Added network-doctor function to your PowerShell profile." -ForegroundColor Green
        Write-Host "Restart PowerShell or run: . `$PROFILE" -ForegroundColor Yellow
    } else {
        Write-Host "network-doctor function already exists in your profile." -ForegroundColor Yellow
    }
    # Check execution policy
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "AllSigned") {
        Write-Host ""
        Write-Warning "Your CurrentUser execution policy is too restrictive ($currentPolicy)."
        Write-Host "The alias will be added, but you won't be able to use it until you fix the policy." -ForegroundColor Yellow
        $fix = Read-Host "Would you like to set execution policy to RemoteSigned for CurrentUser? (yes/no)"
        if ($fix -eq "yes") {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Host "Execution policy set to RemoteSigned for CurrentUser." -ForegroundColor Green
            Write-Host "You may still need to restart PowerShell." -ForegroundColor Yellow
        }
    }

    # Try to load the profile in current session if possible
    try {
        . $PROFILE.CurrentUserAllHosts -ErrorAction Stop
        Write-Host "Profile reloaded successfully in current session." -ForegroundColor Green
    } catch {
        Write-Host "Could not reload profile in this session (common in elevated prompts)." -ForegroundColor Yellow
        Write-Host "Restart PowerShell after installation for the alias to work." -ForegroundColor Yellow
    }
}

Write-Host "`nInstallation complete!" -ForegroundColor Green
Write-Host "Run with: powershell -File `$env:USERPROFILE\Tools\NetworkDoctor.ps1" -ForegroundColor Cyan
if ($CreateAlias) {
    Write-Host "Or simply type: network-doctor" -ForegroundColor White
    # Check execution policy
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "AllSigned") {
        Write-Host ""
        Write-Warning "Your CurrentUser execution policy is too restrictive ($currentPolicy)."
        Write-Host "The alias will be added, but you won't be able to use it until you fix the policy." -ForegroundColor Yellow
        $fix = Read-Host "Would you like to set execution policy to RemoteSigned for CurrentUser? (yes/no)"
        if ($fix -eq "yes") {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Host "Execution policy set to RemoteSigned for CurrentUser." -ForegroundColor Green
            Write-Host "You may still need to restart PowerShell." -ForegroundColor Yellow
        }
    }

    # Try to load the profile in current session if possible
    try {
        . $PROFILE.CurrentUserAllHosts -ErrorAction Stop
        Write-Host "Profile reloaded successfully in current session." -ForegroundColor Green
    } catch {
        Write-Host "Could not reload profile in this session (common in elevated prompts)." -ForegroundColor Yellow
        Write-Host "Restart PowerShell after installation for the alias to work." -ForegroundColor Yellow
    }
}
