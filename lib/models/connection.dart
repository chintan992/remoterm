import 'package:uuid/uuid.dart';

enum AuthMethod { password, privateKey }

// Shell options for remote SSH connections
enum RemoteShell { bash, zsh, fish, sh, powershell, pwsh }

extension RemoteShellExtension on RemoteShell {
  String get displayName {
    switch (this) {
      case RemoteShell.bash:
        return 'Bash';
      case RemoteShell.zsh:
        return 'Zsh';
      case RemoteShell.fish:
        return 'Fish';
      case RemoteShell.sh:
        return 'Sh';
      case RemoteShell.powershell:
        return 'PowerShell';
      case RemoteShell.pwsh:
        return 'PowerShell Core';
    }
  }

  String get command {
    switch (this) {
      case RemoteShell.bash:
        return '/bin/bash';
      case RemoteShell.zsh:
        return '/bin/zsh';
      case RemoteShell.fish:
        return '/usr/bin/fish';
      case RemoteShell.sh:
        return '/bin/sh';
      case RemoteShell.powershell:
        return 'powershell -NoLogo';
      case RemoteShell.pwsh:
        return 'pwsh -NoLogo';
    }
  }

  /// Returns a command to initialize the shell environment after session start.
  /// For PowerShell on Windows, this loads user-level PATH from the registry
  /// so that user-installed tools (npm globals, pip, etc.) are accessible.
  String? get initCommand {
    switch (this) {
      case RemoteShell.powershell:
      case RemoteShell.pwsh:
        // Build the PowerShell init command.
        // Use 'd' as a dollar sign constant to avoid Dart $ escaping issues.
        const d = '\$';
        final parts = <String>[
          // 1. Load user PATH from registry
          '${d}userPath = [Environment]::GetEnvironmentVariable("Path", "User")',
          'if (${d}userPath) { ${d}env:Path = ${d}userPath + ";" + ${d}env:Path }',
          // 2. Add npm global directory
          '${d}npmDir = Join-Path ${d}env:APPDATA "npm"',
          'Write-Host "[REMOTERM] npm dir: ${d}npmDir exists: $d(Test-Path ${d}npmDir)"',
          'if (Test-Path ${d}npmDir) { ${d}env:Path = ${d}npmDir + ";" + ${d}env:Path }',
          // 3. Load profile if exists
          'if (Test-Path ${d}PROFILE) { . ${d}PROFILE }',
          // 4. Debug: confirm
          'Write-Host "[REMOTERM] Done. Path now includes:" (${d}env:Path -split ";" | Select-String "npm")',
        ];
        return '${parts.join("; ")}\r';
      default:
        return null;
    }
  }
}

const defaultQuickActions = [
  '\t', // Tab
  '\x1b', // Esc
  '\x03', // Ctrl+C
  '\x04', // Ctrl+D
  '\x1b[A', // Arrow Up
  '\x1b[B', // Arrow Down
  '\x1b[D', // Arrow Left
  '\x1b[C', // Arrow Right
];

class Connection {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final AuthMethod authMethod;
  final bool savePassword;

  // NEW FIELDS
  final String group;
  final List<String> quickActions;
  final String? terminalTheme;
  final DateTime? lastConnected;
  final bool isConnected;
  final RemoteShell remoteShell;

  Connection({
    String? id,
    required this.name,
    required this.host,
    this.port = 22,
    required this.username,
    required this.authMethod,
    this.savePassword = false,
    this.group = 'Uncategorized',
    List<String>? quickActions,
    this.terminalTheme,
    this.lastConnected,
    this.isConnected = false,
    this.remoteShell = RemoteShell.bash,
  }) : id = id ?? const Uuid().v4(),
       quickActions = quickActions ?? defaultQuickActions;

  Connection copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    AuthMethod? authMethod,
    bool? savePassword,
    String? group,
    List<String>? quickActions,
    String? terminalTheme,
    DateTime? lastConnected,
    bool? isConnected,
    RemoteShell? remoteShell,
  }) {
    return Connection(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      authMethod: authMethod ?? this.authMethod,
      savePassword: savePassword ?? this.savePassword,
      group: group ?? this.group,
      quickActions: quickActions ?? this.quickActions,
      terminalTheme: terminalTheme ?? this.terminalTheme,
      lastConnected: lastConnected ?? this.lastConnected,
      isConnected: isConnected ?? this.isConnected,
      remoteShell: remoteShell ?? this.remoteShell,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'authMethod': authMethod.name,
      'savePassword': savePassword,
      'group': group,
      'quickActions': quickActions,
      'terminalTheme': terminalTheme,
      'lastConnected': lastConnected?.toIso8601String(),
      'remoteShell': remoteShell.name,
    };
  }

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'] as String,
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int? ?? 22,
      username: json['username'] as String,
      authMethod: AuthMethod.values.firstWhere(
        (e) => e.name == json['authMethod'],
        orElse: () => AuthMethod.password,
      ),
      savePassword: json['savePassword'] as bool? ?? false,
      group: json['group'] as String? ?? 'Uncategorized',
      quickActions:
          (json['quickActions'] as List<dynamic>?)?.cast<String>() ??
          defaultQuickActions,
      terminalTheme: json['terminalTheme'] as String?,
      lastConnected: json['lastConnected'] != null
          ? DateTime.tryParse(json['lastConnected'] as String)
          : null,
      isConnected: false,
      remoteShell: RemoteShell.values.firstWhere(
        (e) => e.name == json['remoteShell'],
        orElse: () => RemoteShell.bash,
      ),
    );
  }
}
