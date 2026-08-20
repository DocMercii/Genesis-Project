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
copy "%REPO_DIR%launch-public-url.bat" "%USERPROFILE%\\OneDrive\\Desktop\\Genesis Public Chat.bat" /Y >nul

echo Installed:
echo %TARGET%
echo.
echo Double-click Genesis Chat.bat on your Desktop to launch the local chat server.
echo Double-click Genesis Public Chat.bat on your Desktop for public HTTPS testing.
pause
