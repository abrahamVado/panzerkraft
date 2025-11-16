require('dotenv').config();

const path = require('path');
const express = require('express');
const cors = require('cors');

const { initDb } = require('./db');
const { getCurrentUser } = require('./rbac');

const projectsRouter = require('./routes/projects');
const tasksRouter = require('./routes/tasks');
const taskGroupsRouter = require('./routes/taskGroups');
const runsRouter = require('./routes/runs');
const messagesRouter = require('./routes/messages');
const tasksAsCodeRouter = require('./routes/tasksAsCode');


const app = express();

const PORT = process.env.PORT || 4000;
const DATABASE_PATH =
  process.env.DATABASE_PATH || path.join(__dirname, '..', 'data', 'llm-projects.db');

// Initialize DB
initDb(DATABASE_PATH);

// Middleware
app.use(cors());
app.use(express.json());
app.use(getCurrentUser);

// Health check
app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

// Routes
// Projects
app.use('/projects', projectsRouter);

// Tasks inside a project
app.use('/projects/:projectId/tasks', tasksRouter);

// Task groups inside a project
// => /projects/:projectId/groups
app.use('/projects/:projectId/groups', taskGroupsRouter);

// Runs (overview + per-task)
// => /projects/:projectId/runs
app.use('/projects/:projectId/runs', runsRouter);

// Messages per run
// => /runs/:runId/messages
app.use('/runs/:runId/messages', messagesRouter);

// Tasks as code (JSON view/edit)
app.use('/projects/:projectId/tasks-as-code', tasksAsCodeRouter);


// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Error handler
app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error', detail: err.message });
});

// Start
app.listen(PORT, '0.0.0.0', () => {
  console.log(`LLM Project Backend listening on http://localhost:${PORT}`);
});
