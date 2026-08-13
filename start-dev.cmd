@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-dev.ps1"
echo.
echo Onkofizjo está iniciándose.
echo Marketing: http://127.0.0.1:4173/
echo CRM:       http://127.0.0.1:4173/crm.html
echo API:       http://127.0.0.1:8794/api/health
echo.
pause
