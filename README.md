# LLM Project Backend Scaffold

Minimal Node.js + Express + SQLite backend for the LLM Project Manager:

- Projects (with base prompt)
- Tasks
- Task groups
- Task runs
- Task messages (per run)
- Very simple per-project RBAC scaffold (owner / maintainer / operator / viewer)

This is **only a scaffold**: no actual LLM calls yet, but all the core entities and routes exist.

## Stack

- Node.js
- Express
- better-sqlite3
- SQLite file DB
- CORS enabled (so your Electron / frontend app can talk to it)

## Install

```bash
npm install
cp .env.example .env   # adjust if needed
```

By default:

- `PORT=4000`
- `DATABASE_PATH=./data/llm-projects.db`

## Run

```bash
npm run dev
# or
npm start
```

Server starts on:

- `http://localhost:4000`

## Main routes

### Health

- `GET /health` → `{ ok: true }`

### Projects

- `GET  /projects` – list projects
- `POST /projects` – create project
- `GET  /projects/:projectId` – get single project
- `PUT  /projects/:projectId` – update project (maintainer+)
- `DELETE /projects/:projectId` – delete project (owner)

Body for create/update:

```json
{
  "title": "My project",
  "description": "Optional",
  "base_prompt": "System prompt for this project"
}
```

### Tasks

- `GET  /projects/:projectId/tasks` – list tasks in project
- `POST /projects/:projectId/tasks` – create task (maintainer+)
- `GET  /projects/:projectId/tasks/:taskId` – get task
- `PUT  /projects/:projectId/tasks/:taskId` – update task (maintainer+)
- `DELETE /projects/:projectId/tasks/:taskId` – delete task (maintainer+)

Body (create/update):

```json
{
  "title": "Implement auth flow",
  "description": "Details...",
  "status": "idle",
  "priority": 0,
  "task_prompt": "Optional task-specific prompt override"
}
```

### Task Groups

- `GET  /projects/:projectId/groups` – list groups
- `POST /projects/:projectId/groups` – create group (maintainer+)
- `PUT  /projects/:projectId/groups/:groupId` – update group (maintainer+)
- `DELETE /projects/:projectId/groups/:groupId` – delete group (maintainer+)
- `POST /projects/:projectId/groups/:groupId/tasks` – add tasks to group
- `DELETE /projects/:projectId/groups/:groupId/tasks/:taskId` – remove task from group

### Runs (per project)

- `GET  /projects/:projectId/runs` – list runs for project
  - optional `?taskId=123` to filter by task
- `POST /projects/:projectId/runs/tasks/:taskId/start` – start a new run for a task (operator+)
- `PUT  /projects/:projectId/runs/:runId` – update run (status, summary, finished_at) (operator+)

### Messages (per run)

- `GET  /runs/:runId/messages` – list messages (system/assistant/user) for that run
- `POST /runs/:runId/messages` – append a message (operator+)

Body:

```json
{
  "role": "user",
  "content": "Explain the design choice for this task"
}
```

> Note: There is **no LLM call** here yet. This route simply stores messages; you can later hook an Ollama/OpenAI client that, on `POST`, calls the model and inserts an assistant message.

## RBAC stub

- `src/rbac.js` includes:
  - `getCurrentUser` – currently always sets `req.user = { id: 1 }`.
  - `requireProjectRole(minRole)` – checks `project_roles` table.

On project creation, the current user is automatically assigned role `owner`.

For now, if a project has no entry in `project_roles` for the current user, it assumes `owner` (so you are never locked out during early dev). Change that later when you plug in real users.

---

You can now point your Electron/frontend app at `http://localhost:4000` and build out:

- Project list → `/projects`
- Project detail → `/projects/:id`
- Tasks tab → `/projects/:id/tasks`
- Groups tab → `/projects/:id/groups`
- Runs/Overview tab → `/projects/:id/runs`
- Task chat page → `/runs/:runId/messages`
