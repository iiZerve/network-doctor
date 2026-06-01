@echo off
setlocal
set "SCRIPT_DIR=%~dp0"

echo Launching Network Doctor (forcing execution policy bypass)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%src\AdvancedNetworkMonitor.ps1" %*
