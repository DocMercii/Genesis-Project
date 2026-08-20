const chatEl = document.getElementById("chat");
const statusEl = document.getElementById("status");
const formEl = document.getElementById("chatForm");
const messageEl = document.getElementById("message");
const sendBtn = document.getElementById("send");
const clearBtn = document.getElementById("clear");

const history = [];

function bubble(text, who) {
  const node = document.createElement("div");
  node.className = `bubble ${who}`;
  node.textContent = text;
  chatEl.appendChild(node);
  chatEl.scrollTop = chatEl.scrollHeight;
}

function setStatus(text, isError = false) {
  statusEl.textContent = text;
  statusEl.classList.toggle("error", isError);
}

async function sendMessage(event) {
  event.preventDefault();
  const content = messageEl.value.trim();
  if (!content) return;

  bubble(content, "you");
  history.push({ role: "user", content });
  messageEl.value = "";

  sendBtn.disabled = true;
  setStatus("Thinking...");

  try {
    const response = await fetch("/api/chat", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message: content, history }),
    });
    const result = await response.json();

    if (!response.ok) {
      throw new Error(result.error || "Request failed");
    }

    const reply = result.reply || "";
    bubble(reply, "bot");
    history.push({ role: "assistant", content: reply });
    setStatus("");
  } catch (error) {
    history.pop();
    setStatus(error.message || "Failed to send", true);
    bubble("Request failed. Try again.", "bot");
  } finally {
    sendBtn.disabled = false;
    messageEl.focus();
  }
}

clearBtn.addEventListener("click", () => {
  history.length = 0;
  chatEl.innerHTML = "";
  setStatus("Conversation cleared");
});

formEl.addEventListener("submit", sendMessage);
