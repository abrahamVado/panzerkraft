// src/routes/taskGroups.js
const express = require('express');
const dbModule = require('../db');
const { requireProjectRole } = require('../rbac');

const router = express.Router({ mergeParams: true });

// GET /projects/:projectId/task-groups
router.get('/', (req, res) => {
  const projectId = Number(req.params.projectId);

  const rows = dbModule.db
    .prepare(
      `
      SELECT g.*,
             COUNT(tgm.task_id) AS task_count
      FROM task_groups g
      LEFT JOIN task_group_memberships tgm ON tgm.group_id = g.id
      WHERE g.project_id = ?
      GROUP BY g.id
      ORDER BY g.created_at DESC
    `
    )
    .all(projectId);

  res.json(rows);
});

// POST /projects/:projectId/task-groups
router.post('/', requireProjectRole('maintainer'), (req, res) => {
  const projectId = Number(req.params.projectId);
  const { title, description } = req.body;

  if (!title) {
    return res.status(400).json({ error: 'title is required' });
  }

  const now = new Date().toISOString();

  const info = dbModule.db
    .prepare(
      `
      INSERT INTO task_groups (project_id, title, description, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?)
    `
    )
    .run(projectId, title, description || '', now, now);

  const group = dbModule.db
    .prepare('SELECT * FROM task_groups WHERE id = ?')
    .get(info.lastInsertRowid);

  res.status(201).json(group);
});

// POST /projects/:projectId/task-groups/:groupId/tasks
// body: { taskIds: number[] }
router.post(
  '/:groupId/tasks',
  requireProjectRole('maintainer'),
  (req, res) => {
    const projectId = Number(req.params.projectId);
    const groupId = Number(req.params.groupId);
    const { taskIds } = req.body;

    if (!Array.isArray(taskIds) || taskIds.length === 0) {
      return res.status(400).json({ error: 'taskIds must be a non-empty array' });
    }

    const trx = dbModule.db.transaction((ids) => {
      // Optional safety: ensure group belongs to project
      const group = dbModule.db
        .prepare('SELECT * FROM task_groups WHERE id = ? AND project_id = ?')
        .get(groupId, projectId);
      if (!group) {
        throw new Error('Group not found for this project');
      }

      const stmtUpsert = dbModule.db.prepare(
        `
        INSERT OR IGNORE INTO task_group_memberships (group_id, task_id)
        VALUES (?, ?)
      `
      );

      ids.forEach((taskId) => {
        stmtUpsert.run(groupId, taskId);
      });
    });

    try {
      trx(taskIds);
      res.json({ success: true });
    } catch (err) {
      console.error(err);
      res.status(400).json({ error: err.message || 'Failed to assign tasks' });
    }
  }
);

// PUT /projects/:projectId/groups/:groupId
router.put('/:groupId', requireProjectRole('maintainer'), (req, res) => {
  const projectId = Number(req.params.projectId);
  const groupId = Number(req.params.groupId);
  const { title, description } = req.body;

  const existing = dbModule.db
    .prepare('SELECT * FROM task_groups WHERE id = ? AND project_id = ?')
    .get(groupId, projectId);

  if (!existing) {
    return res.status(404).json({ error: 'Group not found for this project' });
  }

  const now = new Date().toISOString();

  dbModule.db
    .prepare(
      `
      UPDATE task_groups
      SET title = COALESCE(?, title),
          description = COALESCE(?, description),
          updated_at = ?
      WHERE id = ? AND project_id = ?
    `
    )
    .run(title ?? null, description ?? null, now, groupId, projectId);

  const updated = dbModule.db
    .prepare('SELECT * FROM task_groups WHERE id = ?')
    .get(groupId);

  res.json(updated);
});

// DELETE /projects/:projectId/groups/:groupId
router.delete('/:groupId', requireProjectRole('maintainer'), (req, res) => {
  const projectId = Number(req.params.projectId);
  const groupId = Number(req.params.groupId);

  // Remove memberships first
  dbModule.db
    .prepare('DELETE FROM task_group_memberships WHERE group_id = ?')
    .run(groupId);

  const info = dbModule.db
    .prepare('DELETE FROM task_groups WHERE id = ? AND project_id = ?')
    .run(groupId, projectId);

  if (info.changes === 0) {
    return res.status(404).json({ error: 'Group not found for this project' });
  }

  res.json({ success: true });
});

// DELETE /projects/:projectId/groups/:groupId/tasks/:taskId
router.delete(
  '/:groupId/tasks/:taskId',
  requireProjectRole('maintainer'),
  (req, res) => {
    const groupId = Number(req.params.groupId);
    const taskId = Number(req.params.taskId);

    const info = dbModule.db
      .prepare(
        `
        DELETE FROM task_group_memberships
        WHERE group_id = ? AND task_id = ?
      `
      )
      .run(groupId, taskId);

    if (info.changes === 0) {
      return res
        .status(404)
        .json({ error: 'Membership not found for given group/task' });
    }

    res.json({ success: true });
  }
);

// PUT /projects/:projectId/groups/:groupId (if you don't have it yet)
// optional, because your client has updateTaskGroup
router.put('/:groupId', requireProjectRole('maintainer'), (req, res) => {
  const projectId = Number(req.params.projectId);
  const groupId = Number(req.params.groupId);
  const { title, description } = req.body;

  const existing = dbModule.db
    .prepare('SELECT * FROM task_groups WHERE id = ? AND project_id = ?')
    .get(groupId, projectId);

  if (!existing) {
    return res.status(404).json({ error: 'Group not found for this project' });
  }

  const now = new Date().toISOString();

  dbModule.db
    .prepare(
      `
      UPDATE task_groups
      SET title = COALESCE(?, title),
          description = COALESCE(?, description),
          updated_at = ?
      WHERE id = ? AND project_id = ?
    `
    )
    .run(title ?? null, description ?? null, now, groupId, projectId);

  const updated = dbModule.db
    .prepare('SELECT * FROM task_groups WHERE id = ?')
    .get(groupId);

  res.json(updated);
});

// DELETE /projects/:projectId/groups/:groupId
router.delete('/:groupId', requireProjectRole('maintainer'), (req, res) => {
  const projectId = Number(req.params.projectId);
  const groupId = Number(req.params.groupId);

  // Remove memberships first
  dbModule.db
    .prepare('DELETE FROM task_group_memberships WHERE group_id = ?')
    .run(groupId);

  const info = dbModule.db
    .prepare('DELETE FROM task_groups WHERE id = ? AND project_id = ?')
    .run(groupId, projectId);

  if (info.changes === 0) {
    return res.status(404).json({ error: 'Group not found for this project' });
  }

  res.json({ success: true });
});

// DELETE /projects/:projectId/groups/:groupId/tasks/:taskId
router.delete(
  '/:groupId/tasks/:taskId',
  requireProjectRole('maintainer'),
  (req, res) => {
    const groupId = Number(req.params.groupId);
    const taskId = Number(req.params.taskId);

    const info = dbModule.db
      .prepare(
        `
        DELETE FROM task_group_memberships
        WHERE group_id = ? AND task_id = ?
      `
      )
      .run(groupId, taskId);

    if (info.changes === 0) {
      return res
        .status(404)
        .json({ error: 'Membership not found for given group/task' });
    }

    res.json({ success: true });
  }
);



module.exports = router;
