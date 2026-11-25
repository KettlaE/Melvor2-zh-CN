@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-Overlay.ps1"
set ERR=%ERRORLEVEL%
if not "%ERR%"=="0" (
  echo.
  echo Install failed. See the messages above.
  pause
  exit /b %ERR%
)
echo.
pause
exit /b 0
