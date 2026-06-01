@echo off
setlocal
echo Running Network Doctor installer (bypassing execution policy)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
