@echo off
setlocal EnableExtensions

set "REPO_DIR=C:\Users\thoma\OneDrive\Desktop\Uncensored\Genesis-Project"
set "PAGES_URL=https://docmercii.github.io/Genesis-Project/"
set "PORT=7860"

if not exist "%REPO_DIR%" (
  echo Repo path not found: %REPO_DIR%
  pause
  exit /b 1
)

cd /d "%REPO_DIR%"

if not exist "%REPO_DIR%\\.venv\\Scripts\\python.exe" (
  echo Virtual environment not found.
  echo Run:
  echo   python -m venv .venv
  echo   .venv\\Scripts\\activate
  echo   pip install -r requirements.txt
  pause
  exit /b 1
)

call "%REPO_DIR%\\.venv\\Scripts\\activate"

set "HOST=0.0.0.0"
set "OLLAMA_URL=http://127.0.0.1:11434"
set "OLLAMA_MODEL=qwen2.5:7b"

echo.
echo Starting Genesis backend in a background window...
start "Genesis Backend" /min "%REPO_DIR%\\.venv\\Scripts\\python.exe" "%REPO_DIR%\\app.py"
timeout /t 2 >nul

where cloudflared >nul 2>nul
if not errorlevel 1 (
  echo Cloudflare Tunnel found: launching public URL.
  start "Genesis Tunnel" /min cloudflared tunnel --url "http://127.0.0.1:%PORT%"
  echo Open GitHub Pages and test with this backend:
  echo   %PAGES_URL%
  echo.
  echo If Cloudflared prints a public URL, append it to your browser as:
  echo   [github_pages_url]?backend=[public_url]/api/chat
  echo Then use the page normally.
  echo Keep this script window open while testing.
  goto :wait
)

where npx >nul 2>nul
if errorlevel 1 (
  echo.
  echo Neither cloudflared nor Node/npx are installed.
  echo Install Node.js or Cloudflare Tunnel for remote access.
  pause
  exit /b 1
)

echo Starting LocalTunnel (temporary URL). Copy the URL printed below:
npx -y localtunnel --port %PORT%

:wait
pause
