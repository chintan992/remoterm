# Phase 2: Workspace Virtualization - AI Office & Cubicles

## Objectives
Implement the "Sandboxed" development environment where AI agents can operate safely without touching the primary source code.

## Status: ✅ COMPLETE

### 1. Workspace Models
- [x] Create `AiOffice` and `Cubicle` data models.
- [x] Implement JSON serialization for persistence.

### 2. File System Orchestration
- [x] Implement `WorkspaceService` for automated project cloning.
- [x] Add logic to skip heavy/unnecessary directories (`.git`, `node_modules`, `build`, etc.) during cubicle creation.
- [x] Implement directory isolation to prevent cross-cubicle pollution.

### 3. Cubicle Management
- [x] UI for selecting a local project to "Office-ify".
- [x] UI for instantiating multiple "Cubicles" (sandboxes) for different tasks (e.g., bugfix, feature-x).
- [x] Automated directory cleanup when a cubicle is deleted.
