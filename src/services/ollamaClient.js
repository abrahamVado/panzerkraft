// src/services/ollamaClient.js
const fetch = require('node-fetch');

const DEFAULT_OLLAMA_URL =
  process.env.OLLAMA_URL || 'http://127.0.0.1:11434/api/chat';
const DEFAULT_OLLAMA_MODEL =
  process.env.OLLAMA_MODEL || 'qwen2.5-coder:7b';

async function sendChatToOllama({ messages, model, stream = false }) {
  //1.- Build the payload that Ollama expects using defaults when callers omit options.
  const payload = {
    model: model || DEFAULT_OLLAMA_MODEL,
    messages,
    stream,
  };

  //2.- Issue the HTTP POST against the Ollama server and fail fast when it is unreachable.
  const response = await fetch(DEFAULT_OLLAMA_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    //3.- Surface the HTTP layer failure to upstream callers for proper error handling.
    throw new Error(
      `Failed to contact Ollama: ${response.status} ${response.statusText}`,
    );
  }

  //4.- Return the parsed JSON body so routes can forward the AI response back to clients.
  const data = await response.json();
  return data;
}

module.exports = { sendChatToOllama };
