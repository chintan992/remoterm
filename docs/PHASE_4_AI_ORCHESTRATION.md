# Phase 4: AI Orchestration - Productivity & Macros

## Objectives
Enhance the interface between the human operator and the AI CLI tools to maximize throughput and minimize repetitive typing.

## Status: 🟡 PLANNED

### 1. AI Command Palette
- [ ] Implement a slide-out "Macro Panel" for common prompts (e.g., `/explain`, `/refactor`, `/generate-tests`).
- [ ] Allow users to define custom macros per Cubicle or per Office.
- [ ] Support for multi-line prompt injection.

### 2. Tool-Specific Integration
- [x] Pre-configured launch presets (Opencode, Kilocode, Claude Code, Aider).
- [ ] Dynamic parameter passing to presets (e.g., choosing a model before launch).

### 3. Contextual Awareness
- [ ] Implement "Read-Only" mode toggle to prevent AI from writing to disk until explicitly permitted.
- [ ] Capture AI-generated file paths from terminal output to provide "Quick Open" links.
