@echo off
setlocal
set "REPO_DIR=%~dp0"
set "DESKTOP_DIR=%USERPROFILE%\Desktop"
if not exist "%DESKTOP_DIR%" set "DESKTOP_DIR=%USERPROFILE%\OneDrive\Desktop"
if not exist "%DESKTOP_DIR%" (
  echo No desktop directory found.
  echo Tried:
  echo %USERPROFILE%\Desktop
  echo %USERPROFILE%\OneDrive\Desktop
  pause
  exit /b 1
)

set "TARGET=%DESKTOP_DIR%\Genesis Chat.bat"
set "TARGET_PUBLIC=%DESKTOP_DIR%\Genesis Public Chat.bat"
set "TARGET_ONCLICK=%DESKTOP_DIR%\Genesis Public One-Click.bat"

copy "%REPO_DIR%launch-chat.bat" "%TARGET%" /Y >nul
if errorlevel 1 (
  echo Failed to place launcher on desktop:
  echo %DESKTOP_DIR%
  pause
  exit /b 1
)

copy "%REPO_DIR%launch-public-url.bat" "%TARGET_PUBLIC%" /Y >nul
copy "%REPO_DIR%launch-public-oneclick.bat" "%TARGET_ONCLICK%" /Y >nul

echo Installed:
echo %TARGET%
echo.
echo Double-click Genesis Chat.bat on your Desktop to launch the local chat server.
echo Double-click Genesis Public Chat.bat on your Desktop for public HTTPS testing.
echo Double-click Genesis Public One-Click.bat on your Desktop for one-click public testing.
echo.
echo Files were placed in:
echo %DESKTOP_DIR%
pause
