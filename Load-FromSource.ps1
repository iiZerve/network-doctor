<#
.SYNOPSIS
    Loads NetworkDoctor module directly from this repository (for development/testing).
#>

$modulePath = Join-Path $PSScriptRoot "src\NetworkDoctor"

if (Test-Path (Join-Path $modulePath "NetworkDoctor.psd1")) {
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
    Import-Module NetworkDoctor -Force
    Write-Host "NetworkDoctor module loaded from source." -ForegroundColor Green
    Write-Host "Available commands: Start-NetworkDoctor, Update-NetworkDoctor, Get-NetworkReport, etc."
} else {
    Write-Error "Module manifest not found at $modulePath"
}
