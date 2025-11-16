// src/routes/messages.js
const express = require('express');
const dbModule = require('../db');

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
router.post('/', (req, res) => {
  const runId = Number(req.params.runId);
  const { role, content } = req.body;

  if (!role || !content) {
    return res.status(400).json({ error: 'role and content are required' });
  }

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

  res.status(201).json(message);
});

module.exports = router;
