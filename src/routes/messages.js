// src/routes/messages.js
const express = require('express');
const dbModule = require('../db');
const { sendChatToOllama } = require('../services/ollamaClient');

const router = express.Router({ mergeParams: true });

// GET /runs/:runId/messages
router.get('/', (req, res) => {
  const runId = Number(req.params.runId);

  const rows = dbModule.db
    .prepare(
      `
      SELECT *
      FROM task_messages
      WHERE task_run_id = ?
      ORDER BY created_at ASC
    `
    )
    .all(runId);

  res.json(rows);
});

// POST /runs/:runId/messages
// body: { role: 'user' | 'assistant' | 'system', content: string }
router.post('/', async (req, res) => {
  const runId = Number(req.params.runId);
  const { role, content } = req.body;

  if (!role || !content) {
    return res.status(400).json({ error: 'role and content are required' });
  }

  try {
    const now = new Date().toISOString();

    const info = dbModule.db
      .prepare(
        `
        INSERT INTO task_messages (task_run_id, role, content, created_at)
        VALUES (?, ?, ?, ?)
      `
      )
      .run(runId, role, content, now);

    const message = dbModule.db
      .prepare('SELECT * FROM task_messages WHERE id = ?')
      .get(info.lastInsertRowid);

    //1.- If the client sent a user message we gather the conversation and forward it to Ollama.
    if (role === 'user') {
      const conversation = dbModule.db
        .prepare(
          `
          SELECT role, content
          FROM task_messages
          WHERE task_run_id = ?
          ORDER BY created_at ASC
        `
        )
        .all(runId);

      //2.- Send the ordered chat history to the Ollama chat endpoint using the helper service.
      const ollamaResponse = await sendChatToOllama({
        messages: conversation,
        stream: false,
      });

      const assistantContent =
        ollamaResponse?.message?.content?.trim() ||
        '[Assistant response unavailable]';

      const assistantInfo = dbModule.db
        .prepare(
          `
          INSERT INTO task_messages (task_run_id, role, content, created_at)
          VALUES (?, 'assistant', ?, ?)
        `
        )
        .run(runId, assistantContent, new Date().toISOString());

      const assistantMessage = dbModule.db
        .prepare('SELECT * FROM task_messages WHERE id = ?')
        .get(assistantInfo.lastInsertRowid);

      //3.- Return both the stored user message and the AI reply with the raw Ollama payload for transparency.
      return res.status(201).json({
        userMessage: message,
        assistantMessage,
        ollamaResponse,
      });
    }

    //4.- Non-user messages are stored and echoed back without calling Ollama.
    return res.status(201).json({ userMessage: message });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: 'Failed to send message', detail: error.message });
  }
});

module.exports = router;
