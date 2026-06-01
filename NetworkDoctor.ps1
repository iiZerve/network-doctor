<#
.SYNOPSIS
    Network Doctor Launcher
.DESCRIPTION
    Tries to run the tool. If blocked by execution policy, gives clear instructions.
#>

try {
    $scriptPath = Join-Path $PSScriptRoot "src\AdvancedNetworkMonitor.ps1"
    if (Test-Path $scriptPath) {
        & $scriptPath @args
    } else {
        Write-Error "Main script not found."
    }
} catch [System.Management.Automation.PSSecurityException] {
    Write-Host "`nPowerShell execution policy is blocking .ps1 files in this session." -ForegroundColor Yellow
    Write-Host "Please use the .cmd launcher instead:" -ForegroundColor Cyan
    Write-Host "    .\NetworkDoctor.cmd" -ForegroundColor White
    Write-Host ""
    Write-Host "Or run with explicit bypass:" -ForegroundColor Cyan
    Write-Host "    powershell -ExecutionPolicy Bypass -File .\NetworkDoctor.ps1" -ForegroundColor White
} catch {
    throw
}
