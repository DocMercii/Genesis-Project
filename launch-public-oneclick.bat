@echo off
setlocal

set "REPO_DIR=C:\Users\thoma\OneDrive\Desktop\Uncensored\Genesis-Project"
if not exist "%REPO_DIR%" (
  echo Repo path not found: %REPO_DIR%
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%REPO_DIR%\launch-public-oneclick.ps1"
