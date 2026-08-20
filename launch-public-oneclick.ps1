[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$repoDir = "C:\Users\thoma\OneDrive\Desktop\Uncensored\Genesis-Project"
$githubPage = "https://docmercii.github.io/Genesis-Project/"
$port = 7860
$ollamaUrl = "http://127.0.0.1:11434"
$ollamaModel = "qwen2.5:7b"

if (-not (Test-Path (Join-Path $repoDir ".venv\Scripts\python.exe"))) {
    Write-Host "Python venv not found. Run:"
    Write-Host "  python -m venv .venv"
    Write-Host "  .venv\Scripts\activate"
    Write-Host "  pip install -r requirements.txt"
    Read-Host "Press Enter to exit"
    exit 1
}

Push-Location $repoDir

$env:HOST = "0.0.0.0"
$env:PORT = "$port"
$env:OLLAMA_URL = $ollamaUrl
$env:OLLAMA_MODEL = $ollamaModel

$python = Join-Path $repoDir ".venv\Scripts\python.exe"
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
