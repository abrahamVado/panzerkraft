const express = require('express');
const dbModule = require('../db');
const { requireProjectRole } = require('../rbac');

const router = express.Router();

// List projects for current user (for now, all projects)
router.get('/', (req, res) => {
  const rows = dbModule.db.prepare(`
    SELECT p.*,
      (SELECT COUNT(*) FROM tasks t WHERE t.project_id = p.id) AS task_count,
      (SELECT MAX(tr.started_at) FROM task_runs tr JOIN tasks t ON t.id = tr.task_id WHERE t.project_id = p.id) AS last_run_at
    FROM projects p
    ORDER BY p.created_at DESC
  `).all();
  res.json(rows);
});

// Create project
router.post('/', (req, res) => {
  const { title, description, base_prompt } = req.body;
  if (!title) {
    return res.status(400).json({ error: 'title is required' });
  }
  const now = new Date().toISOString();
  const info = dbModule.db.prepare(`
    INSERT INTO projects (title, description, base_prompt, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?)
  `).run(title, description || '', base_prompt || '', now, now);

  // Assign current user as owner.
  dbModule.db.prepare(`
    INSERT OR REPLACE INTO project_roles (project_id, user_id, role)
    VALUES (?, ?, ?)
  `).run(info.lastInsertRowid, req.user.id, 'owner');

  const project = dbModule.db.prepare('SELECT * FROM projects WHERE id = ?').get(info.lastInsertRowid);
  res.status(201).json(project);
});

// Get single project
router.get('/:projectId', (req, res) => {
  const id = Number(req.params.projectId);
  const project = dbModule.db.prepare('SELECT * FROM projects WHERE id = ?').get(id);
  if (!project) {
    return res.status(404).json({ error: 'Project not found' });
  }
  res.json(project);
});

// Update project
router.put('/:projectId', requireProjectRole('maintainer'), (req, res) => {
  const id = Number(req.params.projectId);
  const existing = dbModule.db.prepare('SELECT * FROM projects WHERE id = ?').get(id);
  if (!existing) {
    return res.status(404).json({ error: 'Project not found' });
  }
  const { title, description, base_prompt } = req.body;
  const now = new Date().toISOString();
  dbModule.db.prepare(`
    UPDATE projects
       SET title = ?, description = ?, base_prompt = ?, updated_at = ?
     WHERE id = ?
  `).run(
    title || existing.title,
    description ?? existing.description,
    base_prompt ?? existing.base_prompt,
    now,
    id
  );
  const updated = dbModule.db.prepare('SELECT * FROM projects WHERE id = ?').get(id);
  res.json(updated);
});

// Delete project
router.delete('/:projectId', requireProjectRole('owner'), (req, res) => {
  const projectId = Number(req.params.projectId);

  // Ensure project exists
  const project = dbModule.db
    .prepare('SELECT * FROM projects WHERE id = ?')
    .get(projectId);

  if (!project) {
    return res.status(404).json({ error: 'Project not found' });
  }

  const trx = dbModule.db.transaction((pid) => {
    // 1) Get all tasks for this project
    const tasks = dbModule.db
      .prepare('SELECT id FROM tasks WHERE project_id = ?')
      .all(pid);
    const taskIds = tasks.map((t) => t.id);

    if (taskIds.length > 0) {
      // 2) Get all runs for those tasks
      const placeholders = taskIds.map(() => '?').join(',');
      const runs = dbModule.db
        .prepare(
          `SELECT id FROM task_runs WHERE task_id IN (${placeholders})`
        )
        .all(...taskIds);
      const runIds = runs.map((r) => r.id);

      if (runIds.length > 0) {
        const runPlaceholders = runIds.map(() => '?').join(',');
        // 3) Delete messages
        dbModule.db
          .prepare(
            `DELETE FROM task_messages WHERE task_run_id IN (${runPlaceholders})`
          )
          .run(...runIds);
        // 4) Delete runs
        dbModule.db
          .prepare(
            `DELETE FROM task_runs WHERE id IN (${runPlaceholders})`
          )
          .run(...runIds);
      }

      // 5) Delete group memberships for those tasks
      dbModule.db
        .prepare(
          `DELETE FROM task_group_memberships WHERE task_id IN (${placeholders})`
        )
        .run(...taskIds);

      // 6) Delete tasks
      dbModule.db
        .prepare(
          `DELETE FROM tasks WHERE id IN (${placeholders})`
        )
        .run(...taskIds);
    }

    // 7) Delete groups & their memberships
    const groups = dbModule.db
      .prepare('SELECT id FROM task_groups WHERE project_id = ?')
      .all(pid);
    const groupIds = groups.map((g) => g.id);

    if (groupIds.length > 0) {
      const groupPlaceholders = groupIds.map(() => '?').join(',');
      dbModule.db
        .prepare(
          `DELETE FROM task_group_memberships WHERE group_id IN (${groupPlaceholders})`
        )
        .run(...groupIds);
      dbModule.db
        .prepare(
          `DELETE FROM task_groups WHERE id IN (${groupPlaceholders})`
        )
        .run(...groupIds);
    }

    // 8) Delete project
    dbModule.db
      .prepare('DELETE FROM projects WHERE id = ?')
      .run(pid);
  });

  try {
    trx(projectId);
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res
      .status(500)
      .json({ error: 'Failed to delete project', detail: err.message });
  }
});

module.exports = router;
