<#
.SYNOPSIS
    Network Doctor - Main Launcher (Execution Policy Resilient)
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repoRoot = $PSScriptRoot
$modulePath = Join-Path $repoRoot "src\NetworkDoctor"

# Try to use the module if it's loadable
$moduleManifest = Join-Path $modulePath "NetworkDoctor.psd1"

if (Test-Path $moduleManifest) {
    # Temporarily add the module folder to PSModulePath so Import-Module works from source
    $env:PSModulePath = "$modulePath;$env:PSModulePath"

    try {
        Import-Module NetworkDoctor -Force -ErrorAction Stop
        if (Get-Command Start-NetworkDoctor -ErrorAction SilentlyContinue) {
            Start-NetworkDoctor
            return
        }
    } catch {
        Write-Warning "Could not load module from source. Falling back to script mode..."
    }
}

# Fallback: Run the original script with Bypass (most reliable)
$scriptPath = Join-Path $repoRoot "src\AdvancedNetworkMonitor.ps1"

if (Test-Path $scriptPath) {
    Write-Host "Launching Network Doctor in script mode (bypassing execution policy)..." -ForegroundColor Yellow
    powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath @args
} else {
    Write-Error "Could not find Network Doctor. The repository appears incomplete."
}
