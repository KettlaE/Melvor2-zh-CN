@echo off
setlocal
title Melvor2 Chinese Patch
echo.
echo ========================================
echo  Melvor Idle 2 EA - Chinese patch
echo  Takes about 2-3 minutes. Do NOT close.
echo ========================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Manage-Patch.ps1" -Action install
set ERR=%ERRORLEVEL%
echo.
if %ERR% NEQ 0 (
  echo [FAILED] exit code %ERR%
  echo Copy any red error text above and send it for help.
) else (
  echo [OK] Done. Start the game from Steam when ready.
  echo Keep language on English / en_GB (Chinese uses this channel).
)
echo.
pause
exit /b %ERR%