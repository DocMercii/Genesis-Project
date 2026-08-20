@echo off
setlocal
set "REPO_DIR=%~dp0"
set "TARGET=%USERPROFILE%\OneDrive\Desktop\Genesis Chat.bat"

copy "%REPO_DIR%launch-chat.bat" "%TARGET%" /Y >nul
if errorlevel 1 (
  echo Failed to place shortcut launcher on desktop.
  echo Make sure OneDrive Desktop is available and writable.
  pause
  exit /b 1
)

echo Installed:
echo %TARGET%
echo.
echo Double-click Genesis Chat.bat on your Desktop to launch the local chat server.
pause
