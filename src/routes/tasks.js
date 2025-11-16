// src/routes/tasks.js
const express = require('express');
const dbModule = require('../db');
const { requireProjectRole } = require('../rbac');

const router = express.Router({ mergeParams: true });

// List tasks for a project
router.get('/', (req, res) => {
  const projectId = Number(req.params.projectId);
  const rows = dbModule.db.prepare(`
    SELECT t.*,
      (SELECT COUNT(*) FROM task_runs r WHERE r.task_id = t.id) AS runs_count
    FROM tasks t
    WHERE t.project_id = ?
    ORDER BY t.created_at ASC
  `).all(projectId);
  res.json(rows);
});

// Create task
router.post('/', requireProjectRole('maintainer'), (req, res) => {
  const projectId = Number(req.params.projectId);
  const { title, description, status, priority, task_prompt } = req.body;

  if (!title) {
    return res.status(400).json({ error: 'title is required' });
  }

  const now = new Date().toISOString();
  const info = dbModule.db.prepare(`
    INSERT INTO tasks (
      project_id, title, description,
      status, priority, task_prompt,
      created_at, updated_at
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    projectId,
    title,
    description || '',
    status || 'idle',
    priority ?? 0,
    task_prompt || '',
    now,
    now
  );

  const task = dbModule.db
    .prepare('SELECT * FROM tasks WHERE id = ?')
    .get(info.lastInsertRowid);

  res.status(201).json(task);
});

// Get single task
router.get('/:taskId', (req, res) => {
  const id = Number(req.params.taskId);
  const task = dbModule.db
    .prepare('SELECT * FROM tasks WHERE id = ?')
    .get(id);

  if (!task) {
    return res.status(404).json({ error: 'Task not found' });
  }

  res.json(task);
});

router.delete('/:taskId', requireProjectRole('maintainer'), (req, res) => {
  const projectId = Number(req.params.projectId);
  const taskId = Number(req.params.taskId);

  const task = dbModule.db
    .prepare('SELECT * FROM tasks WHERE id = ? AND project_id = ?')
    .get(taskId, projectId);

  if (!task) {
    return res.status(404).json({ error: 'Task not found for this project' });
  }

  const trx = dbModule.db.transaction((tid) => {
    // 1) Fetch runs for this task
    const runs = dbModule.db
      .prepare('SELECT id FROM task_runs WHERE task_id = ?')
      .all(tid);
    const runIds = runs.map((r) => r.id);

    if (runIds.length > 0) {
      const runPlaceholders = runIds.map(() => '?').join(',');
      // 2) Delete messages
      dbModule.db
        .prepare(
          `DELETE FROM task_messages WHERE task_run_id IN (${runPlaceholders})`
        )
        .run(...runIds);
      // 3) Delete runs
      dbModule.db
        .prepare(
          `DELETE FROM task_runs WHERE id IN (${runPlaceholders})`
        )
        .run(...runIds);
    }

    // 4) Delete group memberships
    dbModule.db
      .prepare('DELETE FROM task_group_memberships WHERE task_id = ?')
      .run(tid);

    // 5) Delete task
    dbModule.db
      .prepare('DELETE FROM tasks WHERE id = ?')
      .run(tid);
  });

  try {
    trx(taskId);
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res
      .status(500)
      .json({ error: 'Failed to delete task', detail: err.message });
  }
});

// Update task
router.put('/:taskId', requireProjectRole('maintainer'), (req, res) => {
  const id = Number(req.params.taskId);
  const existing = dbModule.db
    .prepare('SELECT * FROM tasks WHERE id = ?')
    .get(id);

  if (!existing) {
    return res.status(404).json({ error: 'Task not found' });
  }

  const { title, description, status, priority, task_prompt } = req.body;
  const now = new Date().toISOString();

  dbModule.db.prepare(`
    UPDATE tasks
       SET title = ?,
           description = ?,
           status = ?,
           priority = ?,
           task_prompt = ?,
           updated_at = ?
     WHERE id = ?
  `).run(
    title || existing.title,
    description ?? existing.description,
    status || existing.status,
    priority ?? existing.priority,
    task_prompt ?? existing.task_prompt,
    now,
    id
  );

  const updated = dbModule.db
    .prepare('SELECT * FROM tasks WHERE id = ?')
    .get(id);

  res.json(updated);
});

// Delete task
router.delete('/:taskId', requireProjectRole('maintainer'), (req, res) => {
  const id = Number(req.params.taskId);
  dbModule.db
    .prepare('DELETE FROM tasks WHERE id = ?')
    .run(id);
  res.json({ success: true });
});

module.exports = router;
