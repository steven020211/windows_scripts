@echo off
>nul 2>&1 net session || (
    powershell -Command "Start-Process -Verb RunAs -FilePath 'cmd.exe' -ArgumentList '/c \"\"%~f0\" %*\"'"
    exit /b
)
cd /d "%~dp0"
powershell -NoExit -ExecutionPolicy Bypass -File "%~dpn0.ps1"
