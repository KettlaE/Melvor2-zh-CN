@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Uninstall-Overlay.ps1"
set ERR=%ERRORLEVEL%
if not "%ERR%"=="0" (
  echo.
  echo Uninstall failed. See the messages above.
  pause
  exit /b %ERR%
)
echo.
pause
exit /b 0
