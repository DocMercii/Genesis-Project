"""Local web chat app backed by a local Ollama model."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, List, Literal
import os
import requests
from flask import Flask, jsonify, render_template, request


Role = Literal["system", "user", "assistant"]
Message = Dict[str, str]
History = List[Message]


@dataclass(frozen=True)
class Settings:
    ollama_url: str = "http://127.0.0.1:11434"
    model: str = "qwen2.5:7b"
    temperature: float = 0.8
    top_p: float = 0.95
    max_context_turns: int = 12
    system_prompt: str = (
        "You are a helpful assistant. Answer clearly and directly, and avoid "
        "unnecessary refusals."
    )
    request_timeout_s: int = 120
    host: str = "0.0.0.0"
    port: int = 7860


def _env_float(name: str, default: float, lo: float, hi: float) -> float:
    try:
        value = float(os.getenv(name, str(default)))
    except (TypeError, ValueError):
        return default
    return max(lo, min(hi, value))


def _env_int(name: str, default: int, lo: int, hi: int) -> int:
    try:
        value = int(os.getenv(name, str(default)))
    except (TypeError, ValueError):
        return default
    return max(lo, min(hi, value))


def _clean_message(role: str, content: str, limit: int = 3000) -> Message:
    return {"role": role, "content": content.strip()[:limit]}


def load_settings() -> Settings:
    return Settings(
        ollama_url=os.getenv("OLLAMA_URL", "http://127.0.0.1:11434"),
        model=os.getenv("OLLAMA_MODEL", "qwen2.5:7b"),
        temperature=_env_float("TEMPERATURE", 0.8, 0.0, 2.0),
        top_p=_env_float("TOP_P", 0.95, 0.0, 1.0),
        max_context_turns=_env_int("MAX_CONTEXT_TURNS", 12, 1, 40),
        system_prompt=os.getenv(
            "SYSTEM_PROMPT",
            "You are a helpful assistant. Answer clearly and directly, and avoid "
            "unnecessary refusals.",
        ),
        request_timeout_s=_env_int("REQUEST_TIMEOUT_S", 120, 1, 600),
        host=os.getenv("HOST", "0.0.0.0"),
        port=_env_int("PORT", 7860, 1, 65535),
    )


def limit_history(history: History, max_turns: int) -> History:
    if not isinstance(history, list):
        return []
    valid_roles = {"user", "assistant"}
    filtered = [
        {"role": item.get("role"), "content": str(item.get("content", ""))}
        for item in history
        if isinstance(item, dict) and item.get("role") in valid_roles
    ]
    return filtered[-(max_turns * 2) :]


def ask_ollama(settings: Settings, user_message: str, history: History) -> str:
    clean_history = [_clean_message(item["role"], item["content"]) for item in limit_history(history, settings.max_context_turns)]
    messages: History = [_clean_message("system", settings.system_prompt), *clean_history, _clean_message("user", user_message)]

    payload = {
        "model": settings.model,
        "messages": messages,
        "stream": False,
        "options": {"temperature": settings.temperature, "top_p": settings.top_p},
    }

    response = requests.post(
        f"{settings.ollama_url.rstrip('/')}/api/chat",
        json=payload,
        timeout=settings.request_timeout_s,
    )
    response.raise_for_status()
    data = response.json()
    reply = data.get("message", {}).get("content")
    if not isinstance(reply, str):
        return ""
    return reply.strip()


app = Flask(__name__)


@app.route("/")
def index():
    settings = load_settings()
    return render_template("index.html", model=settings.model)


@app.route("/api/chat", methods=["POST"])
def chat() -> Any:
    settings = load_settings()
    payload = request.get_json(silent=True) or {}

    message = str(payload.get("message", "")).strip()
    history = payload.get("history", [])

    if not message:
        return jsonify({"error": "message is required"}), 400

    try:
        reply = ask_ollama(settings, message, history)
    except requests.RequestException as exc:
        return jsonify({"error": f"LLM request failed: {exc}"}), 502
    except ValueError as exc:
        return jsonify({"error": f"Invalid LLM response: {exc}"}), 502
    except Exception as exc:
        return jsonify({"error": f"Unexpected error: {exc}"}), 500

    return jsonify({"reply": reply or "No response."})


@app.route("/health")
def health():
    settings = load_settings()
    return jsonify({"ok": True, "model": settings.model})


if __name__ == "__main__":
    settings = load_settings()
    app.run(host=settings.host, port=settings.port)
