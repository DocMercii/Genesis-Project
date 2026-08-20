[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$repoDir = "C:\Users\thoma\OneDrive\Desktop\Uncensored\Genesis-Project"
$githubPage = "https://docmercii.github.io/Genesis-Project/"
$port = 7860
$ollamaUrl = "http://127.0.0.1:11434"
$ollamaModel = "qwen2.5:7b"

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
  Write-Host "Python is not on PATH. Install Python 3.10+ and retry."
  Read-Host "Press Enter to exit"
  exit 1
}

$venvPython = Join-Path $repoDir ".venv\Scripts\python.exe"
$venvPip = Join-Path $repoDir ".venv\Scripts\pip.exe"

if (-not (Test-Path $venvPython)) {
  Write-Host "No virtual environment found. Creating one..."
  python -m venv (Join-Path $repoDir ".venv")
}

if (-not (Test-Path $venvPip)) {
  Write-Host "Virtual environment is incomplete. Recreating..."
  Remove-Item -Recurse -Force (Join-Path $repoDir ".venv")
  python -m venv (Join-Path $repoDir ".venv")
}

Write-Host "Installing dependencies..."
& $venvPip install --upgrade pip | Out-Null
& $venvPip install -r (Join-Path $repoDir "requirements.txt")
if ($LASTEXITCODE -ne 0) {
  Write-Host "Failed to install dependencies. Check requirements and network access."
  Read-Host "Press Enter to exit"
  exit 1
}

Push-Location $repoDir

$env:HOST = "0.0.0.0"
$env:PORT = "$port"
$env:OLLAMA_URL = $ollamaUrl
$env:OLLAMA_MODEL = $ollamaModel

$python = $venvPython
$backend = Start-Process -FilePath $python -ArgumentList "app.py" -PassThru

Start-Sleep -Seconds 2

function Extract-Url {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
    if ($Text -match "(https://[^ ]+?\.trycloudflare\.com)") { return $matches[1] }
    if ($Text -match "(https://[^ ]+?\.loca\.lt)") { return $matches[1] }
    return ""
}

function Start-Tunnel {
    param([string]$Command, [string[]]$Args)

    $outFile = Join-Path $env:TEMP ("genesis_tunnel_" + [guid]::NewGuid().ToString() + ".log")
    $errFile = Join-Path $env:TEMP ("genesis_tunnel_err_" + [guid]::NewGuid().ToString() + ".log")
    $proc = Start-Process -FilePath $Command -ArgumentList $Args -NoNewWindow -RedirectStandardOutput $outFile -RedirectStandardError $errFile -PassThru

    $publicUrl = ""
    1..120 | ForEach-Object {
        if (Test-Path $outFile) {
            $text = Get-Content $outFile -Raw -ErrorAction SilentlyContinue
            $publicUrl = Extract-Url $text
            if ($publicUrl) { break }
        }
        Start-Sleep -Milliseconds 500
    }

    return [pscustomobject]@{ Process = $proc; Url = $publicUrl; Log = $outFile; Err = $errFile }
}

Write-Host "Starting public tunnel..."
$tunnel = $null

if (Get-Command cloudflared -ErrorAction SilentlyContinue) {
    $tunnel = Start-Tunnel -Command "cloudflared" -Args @("tunnel", "--url", "http://127.0.0.1:$port")
}

if (-not $tunnel -or -not $tunnel.Url) {
    if (Get-Command npx -ErrorAction SilentlyContinue) {
        $tunnel = Start-Tunnel -Command "npx" -Args @("-y", "localtunnel", "--port", $port)
    }
}

if (-not $tunnel -or -not $tunnel.Url) {
    Write-Host "No tunnel URL detected. Install cloudflared or Node.js (for localtunnel) and retry."
    Write-Host "Try:"
    Write-Host "  winget install Cloudflare.cloudflared"
    Write-Host "  winget install OpenJS.NodeJS"
    Read-Host "Press Enter to stop"
    $backend.Kill()
    exit 1
}

$chatUrl = "$githubPage?backend=$([uri]::EscapeDataString("$($tunnel.Url)/api/chat"))"
Write-Host "Opening: $chatUrl"
Start-Process $chatUrl

Write-Host ""
Write-Host "Backend URL (for manual use): $($tunnel.Url)/api/chat"
Write-Host "Press Enter in this window to stop everything."
Read-Host

$backend.Kill()
$tunnel.Process.Kill()
Pop-Location
