// src/routes/tasksAsCode.js
const express = require('express');
const dbModule = require('../db');
const { requireProjectRole } = require('../rbac');

const router = express.Router({ mergeParams: true });

/**
 * GET /projects/:projectId/tasks-as-code
 * Optional query: ?groupId=123 to focus on one group.
 */
router.get('/', (req, res) => {
  const projectId = Number(req.params.projectId);
  const groupId = req.query.groupId ? Number(req.query.groupId) : null;

  const project = dbModule.db
    .prepare('SELECT id, title, description FROM projects WHERE id = ?')
    .get(projectId);

  if (!project) {
    return res.status(404).json({ error: 'Project not found' });
  }

  // All tasks for the project
  const tasks = dbModule.db
    .prepare(
      `
      SELECT t.*
      FROM tasks t
      WHERE t.project_id = ?
      ORDER BY t.created_at DESC
    `
    )
    .all(projectId);

  // Groups + memberships
  const groups = dbModule.db
    .prepare(
      `
      SELECT g.*
      FROM task_groups g
      WHERE g.project_id = ?
      ORDER BY g.created_at DESC
    `
    )
    .all(projectId);

  const memberships = dbModule.db
    .prepare(
      `
      SELECT group_id, task_id
      FROM task_group_memberships
      WHERE group_id IN (
        SELECT id FROM task_groups WHERE project_id = ?
      )
    `
    )
    .all(projectId);

  const membershipByTaskId = new Map();
  for (const m of memberships) {
    if (!membershipByTaskId.has(m.task_id)) {
      membershipByTaskId.set(m.task_id, []);
    }
    membershipByTaskId.get(m.task_id).push(m.group_id);
  }

  // Build group->tasks mapping
  const groupsOut = groups
    .filter((g) => (groupId ? g.id === groupId : true))
    .map((g) => {
      const groupTaskIds = memberships
        .filter((m) => m.group_id === g.id)
        .map((m) => m.task_id);

      const groupTasks = tasks
        .filter((t) => groupTaskIds.includes(t.id))
        .map(stripTaskFields);

      return {
        id: g.id,
        title: g.title,
        description: g.description,
        tasks: groupTasks
      };
    });

  // Ungrouped = tasks with no membership
  const ungroupedTasks = tasks
    .filter((t) => !membershipByTaskId.has(t.id))
    .map(stripTaskFields);

  res.json({
    project,
    groups: groupsOut,
    ungrouped_tasks: ungroupedTasks
  });
});

/**
 * PUT /projects/:projectId/tasks-as-code
 * Body: JSON in the format described above.
 *
 * Only creates/updates tasks & groups; no automatic deletes.
 */
router.put('/', requireProjectRole('maintainer'), (req, res) => {
  const projectId = Number(req.params.projectId);
  const payload = req.body;

  if (!payload || typeof payload !== 'object') {
    return res.status(400).json({ error: 'Invalid JSON body' });
  }

  const { groups = [], ungrouped_tasks = [] } = payload;

  const trx = dbModule.db.transaction(() => {
    // Process groups and their tasks
    const upsertGroupStmt = dbModule.db.prepare(
      `
      INSERT INTO task_groups (id, project_id, title, description, created_at, updated_at)
      VALUES (@id, @project_id, @title, @description, @created_at, @updated_at)
      ON CONFLICT(id) DO UPDATE SET
        title = excluded.title,
        description = excluded.description,
        updated_at = excluded.updated_at
    `
    );

    const newGroupStmt = dbModule.db.prepare(
      `
      INSERT INTO task_groups (project_id, title, description, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?)
    `
    );

    const upsertTaskStmt = dbModule.db.prepare(
      `
      INSERT INTO tasks (id, project_id, title, description, status, priority, created_at, updated_at)
      VALUES (@id, @project_id, @title, @description, @status, @priority, @created_at, @updated_at)
      ON CONFLICT(id) DO UPDATE SET
        title = excluded.title,
        description = excluded.description,
        status = excluded.status,
        priority = excluded.priority,
        updated_at = excluded.updated_at
    `
    );

    const newTaskStmt = dbModule.db.prepare(
      `
      INSERT INTO tasks (project_id, title, description, status, priority, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `
    );

    const insertMembershipStmt = dbModule.db.prepare(
      `
      INSERT OR IGNORE INTO task_group_memberships (group_id, task_id)
      VALUES (?, ?)
    `
    );

    const now = new Date().toISOString();

    // Map group temp IDs → DB IDs (for new groups)
    const groupIdMap = new Map();

    // First pass: groups and their tasks
    for (const group of groups) {
      let groupId = group.id ?? null;

      if (groupId == null) {
        const info = newGroupStmt.run(
          projectId,
          group.title || '',
          group.description || '',
          now,
          now
        );
        groupId = info.lastInsertRowid;
      } else {
        upsertGroupStmt.run({
          id: groupId,
          project_id: projectId,
          title: group.title || '',
          description: group.description || '',
          created_at: now,
          updated_at: now
        });
      }

      groupIdMap.set(group.id, groupId);

      // Process tasks inside this group
      if (Array.isArray(group.tasks)) {
        for (const t of group.tasks) {
          let taskId = t.id ?? null;

          if (taskId == null) {
            const info = newTaskStmt.run(
              projectId,
              t.title || '',
              t.description || '',
              t.status || 'idle',
              typeof t.priority === 'number' ? t.priority : 0,
              now,
              now
            );
            taskId = info.lastInsertRowid;
          } else {
            upsertTaskStmt.run({
              id: taskId,
              project_id: projectId,
              title: t.title || '',
              description: t.description || '',
              status: t.status || 'idle',
              priority: typeof t.priority === 'number' ? t.priority : 0,
              created_at: now,
              updated_at: now
            });
          }

          insertMembershipStmt.run(groupId, taskId);
        }
      }
    }

    // Second pass: ungrouped tasks (no membership changes)
    for (const t of ungrouped_tasks) {
      let taskId = t.id ?? null;

      if (taskId == null) {
        newTaskStmt.run(
          projectId,
          t.title || '',
          t.description || '',
          t.status || 'idle',
          typeof t.priority === 'number' ? t.priority : 0,
          now,
          now
        );
      } else {
        upsertTaskStmt.run({
          id: taskId,
          project_id: projectId,
          title: t.title || '',
          description: t.description || '',
          status: t.status || 'idle',
          priority: typeof t.priority === 'number' ? t.priority : 0,
          created_at: now,
          updated_at: now
        });
      }
    }
  });

  try {
    trx();
    return res.json({ ok: true });
  } catch (err) {
    console.error(err);
    return res
      .status(500)
      .json({ error: 'Failed to apply tasks-as-code', detail: err.message });
  }
});

function stripTaskFields(t) {
  return {
    id: t.id,
    title: t.title,
    description: t.description,
    status: t.status,
    priority: t.priority
  };
}

module.exports = router;
