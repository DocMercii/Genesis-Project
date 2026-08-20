const endpointInput = document.getElementById("endpoint");
const status = document.getElementById("status");
const chat = document.getElementById("chat");
const messageInput = document.getElementById("message");
const chatForm = document.getElementById("chat-form");
const checkBtn = document.getElementById("check");
const clearBtn = document.getElementById("clear");

const history = [];

function bubble(text, who){
  const d = document.createElement("div");
  d.className = `bubble ${who}`;
  d.textContent = text;
  chat.appendChild(d);
  chat.scrollTop = chat.scrollHeight;
}

function setStatus(text, error=false){
  status.textContent = text;
  status.style.color = error ? "#b91c1c" : "#64748b";
}

function currentEndpoint(){
  const value = (endpointInput.value || "").trim();
  if (!value) return "";
  if (!value.endsWith("/api/chat")) return value.replace(/\/$/, "") + "/api/chat";
  return value;
}

function persistEndpoint() {
  localStorage.setItem("genesis_backend", endpointInput.value);
}

function hydrateEndpoint() {
  const saved = localStorage.getItem("genesis_backend");
  if (saved) endpointInput.value = saved;
}

async function checkConnection(){
  const endpoint = currentEndpoint();
  if (!endpoint) {
    setStatus("Set a backend URL first", true);
    return;
  }
  setStatus("Checking...");
  try {
    const healthUrl = endpoint.replace(/\/api\/chat\/?$/, "/health");
    const r = await fetch(healthUrl);
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    const data = await r.json();
    setStatus(`Connected. Model: ${data.model || "unknown"}`);
  } catch (err) {
    setStatus(`Connection failed: ${err.message}`, true);
  }
}

async function sendMessage(event){
  event.preventDefault();
  const endpoint = currentEndpoint();
  const content = messageInput.value.trim();
  if (!endpoint || !content) return;

  persistEndpoint();
  bubble(content, "you");
  history.push({ role: "user", content });
  messageInput.value = "";
  setStatus("Thinking...");

  try{
    const response = await fetch(endpoint, {
      method:"POST",
      headers:{ "Content-Type":"application/json" },
      body: JSON.stringify({ message: content, history })
    });
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Request failed");
    const reply = data.reply || "";
    bubble(reply, "bot");
    history.push({ role:"assistant", content: reply });
    setStatus("Ready");
  }catch(err){
    setStatus(err.message || "Failed to send", true);
    history.pop();
    bubble("Request failed. Check backend URL and CORS.", "bot");
  }
}

checkBtn.addEventListener("click", checkConnection);
clearBtn.addEventListener("click", () => { history.length=0; chat.innerHTML=""; setStatus("Conversation cleared"); });
chatForm.addEventListener("submit", sendMessage);
endpointInput.addEventListener("blur", persistEndpoint);

hydrateEndpoint();
