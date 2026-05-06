@echo off
REM Attend que le lecteur reseau Z: soit disponible (max ~30s)
set /a tries=0
:waitdrive
if exist "Z:\CAO\Workspace" goto run
set /a tries+=1
if %tries% geq 15 goto run
timeout /t 2 /nobreak >nul
goto waitdrive

:run
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0delete_random_file.ps1" "Z:\CAO\Workspace"
