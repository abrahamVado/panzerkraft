import { contextBridge, ipcRenderer } from 'electron';
const NS = 'panzerkraft' as const;
const api = { ping: () => ipcRenderer.invoke(`${NS}:ping`) };
contextBridge.exposeInMainWorld(NS, api);