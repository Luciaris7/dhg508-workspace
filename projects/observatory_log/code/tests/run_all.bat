@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run.ps1" all
set "RESULT=%ERRORLEVEL%"
pause
exit /b %RESULT%
