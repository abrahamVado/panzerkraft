// panzerkraft/src/index.ts
// SUPER COMMENTS — IMPLEMENTATION ROADMAP
import { ipcMain } from 'electron';
const NS = 'panzerkraft' as const;
export function activate() {
  ipcMain.handle(`${NS}:ping`, () => ({ ok: true, purpose: "Task/epic/project manager focused on structure, time, and discipline." }));
}
export function deactivate() {
  ipcMain.removeHandler(`${NS}:ping`);
}