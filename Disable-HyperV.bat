@echo off
powershell -Command "Start-Process -Verb RunAs -FilePath 'powershell.exe' -ArgumentList '-NoExit -ExecutionPolicy Bypass -File \"%~dpn0.ps1\"' -Wait"
