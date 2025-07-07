@echo off
REM Flutter Linter Debug Script - Batch Wrapper
REM This batch file makes it easy to run the PowerShell debug script

echo Flutter Linter Debug Script
echo ===========================

REM Check if PowerShell is available
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: PowerShell is not available
    pause
    exit /b 1
)

REM Run the PowerShell script with all arguments passed through
powershell -ExecutionPolicy Bypass -File "%~dp0debug_linter.ps1" %*

REM Pause to see results
pause 