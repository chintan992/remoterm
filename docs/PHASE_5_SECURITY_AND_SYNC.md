# Phase 5: Security & Synchronization - Production Readiness

## Objectives
Ensure the integrity of the "Source of Truth" (Main Project) and enforce strict security boundaries.

## Status: 🟡 PLANNED

### 1. Advanced Synchronization Engine
- [x] Basic "Sync to Main" logic (Directory Copy).
- [ ] Implement Git-aware syncing (checking for clean index before sync).
- [ ] Add "Dry Run / Diff Preview" before committing cubicle changes to the main project.
- [ ] Support for specific file/folder exclusion patterns during sync.

### 2. Network & Process Security
- [ ] Enforce "Zero Trust" policy: Disable remote telemetry/reporting from within cubicles.
- [ ] Implement PTY process monitoring (auto-kill runaway AI processes).
- [ ] Secure Keychain integration for long-term credential rotation.

### 3. Drift Detection
- [ ] Background monitoring of Cubicle vs. Main Project directory hash.
- [ ] Visual "Drift" percentage indicator in the UI.
- [ ] Notification system for external changes affecting active cubicles.
