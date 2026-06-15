@echo off
REM ====================================================================
REM  Double-click launcher for fulldevkit.ps1
REM  Auto-elevates to admin (needed for winget installs), bypasses
REM  execution policy, and strips Mark-of-the-Web. Keep this .bat in
REM  the SAME FOLDER as fulldevkit.ps1
REM ====================================================================

REM --- Check for admin; if not, relaunch elevated ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Running Web Dev Environment Audit + Auto-Fix...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem '%~dp0*.ps1' | Unblock-File; & '%~dp0fulldevkit.ps1'"
echo.
echo ====================================================================
echo  Done. Press any key to close this window.
echo ====================================================================
pause >nul
