import 'package:uuid/uuid.dart';

enum AuthMethod { password, privateKey }

const defaultQuickActions = [
  '\t',     // Tab
  '\x1b',   // Esc
  '\x03',   // Ctrl+C
  '\x04',   // Ctrl+D
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
  })  : id = id ?? const Uuid().v4(),
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
      'isConnected': isConnected,
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
      quickActions: (json['quickActions'] as List<dynamic>?)?.cast<String>() ?? defaultQuickActions,
      terminalTheme: json['terminalTheme'] as String?,
      lastConnected: json['lastConnected'] != null 
          ? DateTime.tryParse(json['lastConnected'] as String) 
          : null,
      isConnected: json['isConnected'] as bool? ?? false,
    );
  }
}
