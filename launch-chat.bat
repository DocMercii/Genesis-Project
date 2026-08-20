@echo off
setlocal EnableExtensions

REM Change this path if you keep the repo elsewhere.
set "REPO_DIR=C:\Users\thoma\OneDrive\Desktop\Uncensored\Genesis-Project"

if not exist "%REPO_DIR%" (
  echo Repo path not found: %REPO_DIR%
  echo Update REPO_DIR in launch-chat.bat.
  pause
  exit /b 1
)

cd /d "%REPO_DIR%"

if not exist "%REPO_DIR%\\.venv\\Scripts\\python.exe" (
  echo Virtual environment not found: %REPO_DIR%\\.venv
  echo Run:
  echo   python -m venv .venv
  echo   .venv\\Scripts\\activate
  echo   pip install -r requirements.txt
  pause
  exit /b 1
)

call "%REPO_DIR%\\.venv\\Scripts\\activate"

set "HOST=0.0.0.0"
set "PORT=7860"
set "OLLAMA_URL=http://127.0.0.1:11434"
set "OLLAMA_MODEL=qwen2.5:7b"

echo.
echo ==============================================
echo Starting Genesis local chatbot on %HOST%:%PORT%
echo Open on phone: http://<PC_LOCAL_IP>:%PORT%
echo Press Ctrl+C in this window to stop.
echo ==============================================
python app.py

pause
