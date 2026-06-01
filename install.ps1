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
setlocal
set "SCRIPT=%USERPROFILE%\Tools\NetworkDoctor.ps1"

REM Always launch with Bypass to handle restricted execution policies
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
"@

    $shimContent | Out-File -FilePath $shim -Encoding ASCII -Force
    Write-Host "Created robust command: network-doctor (bypasses execution policy)" -ForegroundColor Green

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
Write-Host "Alternative (most reliable when execution policy is strict):" -ForegroundColor Yellow
Write-Host "    .\NetworkDoctor.cmd   (from the repo folder)" -ForegroundColor White
Write-Host ""
Write-Host "Tip: Restart your terminal / VS Code for PATH changes to apply." -ForegroundColor Yellow

# --- Optional: Install as PowerShell module (recommended for advanced use) ---
Write-Host ""
$installAsModule = Read-Host "Would you also like to install Network Doctor as a proper PowerShell module? (recommended) (yes/no)"
if ($installAsModule -eq 'yes') {
    $userModulePath = if ($PSVersionTable.PSVersion.Major -ge 6) {
        "$env:USERPROFILE\Documents\PowerShell\Modules\NetworkDoctor"
    } else {
        "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\NetworkDoctor"
    }

    if (!(Test-Path $userModulePath)) { 
        New-Item -ItemType Directory -Path $userModulePath -Force | Out-Null 
    }

    $sourceModule = Join-Path $PSScriptRoot "src\NetworkDoctor"
    if (Test-Path $sourceModule) {
        Copy-Item -Path "$sourceModule\*" -Destination $userModulePath -Recurse -Force
        Write-Host "Module installed to: $userModulePath" -ForegroundColor Green
        Write-Host "You can now use: Import-Module NetworkDoctor" -ForegroundColor Cyan
        Write-Host "Then run: Start-NetworkDoctor" -ForegroundColor White
    } else {
        Write-Host "Module source not found. Skipping module installation." -ForegroundColor Yellow
    }
}



# --- Create Desktop and Start Menu shortcuts (makes launching painless) ---
Write-Host ""
$createShortcuts = Read-Host "Create Desktop + Start Menu shortcuts for easy launching? (yes/no)"
if ($createShortcuts -eq 'yes') {
    try {
        $WshShell = New-Object -ComObject WScript.Shell
        
        $target = Join-Path $InstallPath "network-doctor.cmd"
        $workingDir = $InstallPath
        
        # Desktop shortcut
        $desktop = [Environment]::GetFolderPath("Desktop")
        $desktopShortcut = $WshShell.CreateShortcut("$desktop\Network Doctor.lnk")
        $desktopShortcut.TargetPath = $target
        $desktopShortcut.WorkingDirectory = $workingDir
        $desktopShortcut.Description = "Launch Network Doctor - Advanced network diagnostics"
        $desktopShortcut.Save()
        Write-Host "Desktop shortcut created: $desktop\Network Doctor.lnk" -ForegroundColor Green

        # Start Menu shortcut
        $startMenuPrograms = [Environment]::GetFolderPath("StartMenu")
        $startMenuFolder = Join-Path $startMenuPrograms "Programs\Network Doctor"
        if (!(Test-Path $startMenuFolder)) {
            New-Item -ItemType Directory -Path $startMenuFolder -Force | Out-Null
        }
        $startMenuShortcut = $WshShell.CreateShortcut("$startMenuFolder\Network Doctor.lnk")
        $startMenuShortcut.TargetPath = $target
        $startMenuShortcut.WorkingDirectory = $workingDir
        $startMenuShortcut.Description = "Launch Network Doctor"
        $startMenuShortcut.Save()
        Write-Host "Start Menu shortcut created." -ForegroundColor Green

        Write-Host "`nYou can now launch Network Doctor from the Desktop or Start Menu." -ForegroundColor Cyan
    } catch {
        Write-Host "Could not create shortcuts automatically: $_" -ForegroundColor Yellow
        Write-Host "You can create them manually if needed." -ForegroundColor Yellow
    }
}
