@echo off
setlocal
cd /d "%~dp0"
if not exist "%~dp0build\LastOutpostLauncher.exe" (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\build-launcher.ps1"
    if errorlevel 1 (
        echo Impossible de preparer le lanceur. Consultez le message ci-dessus.
        pause
        exit /b 1
    )
)
start "Last Outpost" "%~dp0build\LastOutpostLauncher.exe"
exit /b 0
