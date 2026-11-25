@echo off
setlocal
title Melvor2 Restore Official
echo.
echo ========================================
echo  Melvor Idle 2 EA - Restore official
echo ========================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Manage-Patch.ps1" -Action restore
set ERR=%ERRORLEVEL%
echo.
if %ERR% NEQ 0 (
  echo [FAILED] exit code %ERR%
  echo Copy any red error text above and send it for help.
) else (
  echo [OK] Official Melvor2.exe restored.
)
echo.
pause
exit /b %ERR%