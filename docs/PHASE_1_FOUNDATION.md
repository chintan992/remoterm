# Phase 1: Foundation - SSH & Local PTY Core

## Objectives
Establish the core terminal connectivity and basic state management for Remoterm.

## Status: ✅ COMPLETE

### 1. Terminal Rendering Engine
- [x] Integrate `xterm` package for ANSI sequence parsing.
- [x] Implement `XTermThemeConverter` for Material 3 theme sync.
- [x] Create `TerminalView` wrappers for responsive sizing.

### 2. Remote Connectivity (SSH)
- [x] Integrate `dartssh2` for high-performance SSH tunneling.
- [x] Implement `SSHService` with support for:
    - Password authentication.
    - Private key authentication (RSA/ED25519).
    - Auto-reconnect logic.
- [x] Secure credential storage using `flutter_secure_storage`.

### 3. Local Connectivity (PTY)
- [x] Implement `LocalTerminalService` using Dart `Process`.
- [x] Support for default shell detection (bash/zsh/cmd).
- [x] Basic stdin/stdout piping.

### 4. Basic State Management
- [x] Implement `SavedConnectionsNotifier` for SSH profile CRUD.
- [x] Establish `UIStateProvider` for global terminal font and theme settings.
