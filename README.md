# Genesis — Local Chat App

This repository now runs a **local Flask chat app** backed by a local Ollama model.

## Prerequisites

- Python 3.10+
- Ollama installed and running
- A local model downloaded (example: `ollama pull qwen2.5:7b`)

## Quick setup

```powershell
cd C:\Users\thoma\OneDrive\Desktop\Uncensored\Genesis-Project
python -m venv .venv
.venv\Scripts\Activate
pip install -r requirements.txt
```

## Run (PC + phone)

```powershell
$env:OLLAMA_URL = "http://127.0.0.1:11434"
$env:OLLAMA_MODEL = "qwen2.5:7b"
$env:HOST = "0.0.0.0"
$env:PORT = "7860"
python app.py

## One-click startup (Windows)

From this repository:

```powershell
cd C:\Users\thoma\OneDrive\Desktop\Uncensored\Genesis-Project
install-desktop-shortcut.bat
```

Then double-click `Genesis Chat.bat` or `Genesis Chat.lnk` on your Desktop to launch everything.

The launcher sets:
- `HOST=0.0.0.0`
- `PORT=7860`
- `OLLAMA_URL=http://127.0.0.1:11434`
- `OLLAMA_MODEL=qwen2.5:7b`

After launching, open on phone:
`http://<PC_LOCAL_IP>:7860`

## Public GitHub Pages frontend

A GitHub Pages-ready frontend is included in `docs/`.

1. In GitHub repository settings, open **Pages**.
2. Set source to:
   - **Deploy from a branch**
   - Branch: `main`
   - Folder: `/docs`
3. Visit your GitHub Pages URL:
   - `https://docmercii.github.io/Genesis-Project/` (public URL)
4. In the page, set backend URL to your current machine endpoint:
   - Local network: `http://<PC_LOCAL_IP>:7860/api/chat`
   - Public tunnel (HTTPS): `https://<your-tunnel-domain>/api/chat`

If the page cannot reach an `http://` local endpoint, use HTTPS tunnel URL as noted.
```

### Open from your phone

1. Make sure phone and PC are on the same Wi‑Fi network.
2. Open `http://<your-pc-local-ip>:7860` on your phone.
3. Replace `<your-pc-local-ip>` with your LAN IP (example: `192.168.1.42`).

## Environment variables

- `OLLAMA_URL` (default `http://127.0.0.1:11434`)
- `OLLAMA_MODEL` (default `qwen2.5:7b`)
- `TEMPERATURE` (default `0.8`)
- `TOP_P` (default `0.95`)
- `MAX_CONTEXT_TURNS` (default `12`)
- `REQUEST_TIMEOUT_S` (default `120`)
- `SYSTEM_PROMPT` (default: concise, direct helper behavior)

## API

- `POST /api/chat` with JSON body: `{ "message": "...", "history": [...] }`
- `GET /health` for quick service check.
