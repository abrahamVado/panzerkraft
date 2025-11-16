const dbModule = require('./db');

// Very simple current user stub for scaffolding.
function getCurrentUser(req, _res, next) {
  // For now, always user id 1
  req.user = { id: 1, name: 'Local User' };
  next();
}

function getProjectRole(projectId, userId) {
  const row = dbModule.db
    .prepare(
      'SELECT role FROM project_roles WHERE project_id = ? AND user_id = ?'
    )
    .get(projectId, userId);
  return row ? row.role : null;
}


// Middleware factory to enforce role per project.
function requireProjectRole(minRole) {
  const rank = { viewer: 1, operator: 2, maintainer: 3, owner: 4 };

  return (req, res, next) => {
    const projectId = Number(req.params.projectId || req.body.projectId);
    if (!projectId) {
      return res.status(400).json({ error: 'projectId required for RBAC check' });
    }

    const role = getProjectRole(projectId, req.user.id) || 'owner'; // default owner for scaffolding
    if (rank[role] >= rank[minRole]) {
      req.projectRole = role;
      return next();
    }

    return res.status(403).json({ error: 'Forbidden: insufficient role', role });
  };
}

module.exports = {
  getCurrentUser,
  requireProjectRole
};
