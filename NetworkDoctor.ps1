<#
.SYNOPSIS
    Network Doctor Launcher
.DESCRIPTION
    Launches Network Doctor. Prefers the installed module if available.
#>

$module = Get-Module -ListAvailable NetworkDoctor -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1

if ($module) {
    Import-Module NetworkDoctor -Force
    Start-NetworkDoctor
} else {
    # Fallback to the script in this repo
    $scriptPath = Join-Path $PSScriptRoot "src\AdvancedNetworkMonitor.ps1"
    if (Test-Path $scriptPath) {
        & $scriptPath @args
    } else {
        Write-Error "Could not find Network Doctor. Please run the installer or ensure the script exists."
    }
}
