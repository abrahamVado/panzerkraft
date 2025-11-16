// src/routes/runs.js
const express = require('express');
const dbModule = require('../db');
const { requireProjectRole } = require('../rbac');

const router = express.Router({ mergeParams: true });

/**
 * GET /projects/:projectId/runs
 * Optional query: ?taskId=123 to filter by task.
 */
router.get('/', (req, res) => {
  const projectId = Number(req.params.projectId);
  const taskId = req.query.taskId ? Number(req.query.taskId) : null;

  const baseSql = `
    SELECT tr.*,
           t.title AS task_title
    FROM task_runs tr
    JOIN tasks t ON t.id = tr.task_id
    WHERE t.project_id = ?
    ${taskId ? 'AND tr.task_id = ?' : ''}
    ORDER BY tr.started_at DESC
  `;

  const rows = taskId
    ? dbModule.db.prepare(baseSql).all(projectId, taskId)
    : dbModule.db.prepare(baseSql).all(projectId);

  res.json(rows);
});

/**
 * POST /projects/:projectId/runs/tasks/:taskId/start
 * Starts a new run for a specific task.
 */
router.post(
  '/tasks/:taskId/start',
  requireProjectRole('operator'),
  (req, res) => {
    const projectId = Number(req.params.projectId);
    const taskId = Number(req.params.taskId);

    // Ensure task belongs to this project
    const task = dbModule.db
      .prepare('SELECT * FROM tasks WHERE id = ? AND project_id = ?')
      .get(taskId, projectId);

    if (!task) {
      return res.status(404).json({ error: 'Task not found for this project' });
    }

    const now = new Date().toISOString();

    const info = dbModule.db
      .prepare(
        `
        INSERT INTO task_runs (task_id, status, started_at, finished_at, run_summary)
        VALUES (?, 'running', ?, NULL, NULL)
      `
      )
      .run(taskId, now);

    const run = dbModule.db
      .prepare('SELECT * FROM task_runs WHERE id = ?')
      .get(info.lastInsertRowid);

    res.status(201).json(run);
  }
);

/**
 * PUT /projects/:projectId/runs/:runId
 * Updates status/summary of a run.
 */
router.put(
  '/:runId',
  requireProjectRole('operator'),
  (req, res) => {
    const projectId = Number(req.params.projectId);
    const runId = Number(req.params.runId);
    const { status, run_summary, finished_at } = req.body;

    // Ensure the run belongs to this project (via its task)
    const existing = dbModule.db
      .prepare(
        `
        SELECT tr.*
        FROM task_runs tr
        JOIN tasks t ON t.id = tr.task_id
        WHERE tr.id = ? AND t.project_id = ?
      `
      )
      .get(runId, projectId);

    if (!existing) {
      return res.status(404).json({ error: 'Run not found for this project' });
    }

    const now = new Date().toISOString();

    dbModule.db
      .prepare(
        `
        UPDATE task_runs
        SET status = COALESCE(?, status),
            run_summary = COALESCE(?, run_summary),
            finished_at = COALESCE(?, finished_at)
        WHERE id = ?
      `
      )
      .run(
        status ?? null,
        run_summary ?? null,
        finished_at ?? (status === 'completed' ? now : existing.finished_at),
        runId
      );

    const updated = dbModule.db
      .prepare('SELECT * FROM task_runs WHERE id = ?')
      .get(runId);

    res.json(updated);
  }
);

module.exports = router;
