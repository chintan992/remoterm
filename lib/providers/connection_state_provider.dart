import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/connection.dart';
import '../models/terminal_session_state.dart';
import '../services/ssh_service.dart';
import '../services/secure_storage_service.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class ConnectionState {
  final ConnectionStatus status;
  final Connection? connection;
  final String? errorMessage;

  const ConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.connection,
    this.errorMessage,
  });

  ConnectionState copyWith({
    ConnectionStatus? status,
    Connection? connection,
    String? errorMessage,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      connection: connection ?? this.connection,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static ConnectionState disconnected() {
    return const ConnectionState(status: ConnectionStatus.disconnected);
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final sshServiceProvider = Provider<SSHService>((ref) {
  return SSHService();
});

final connectionStateProvider =
    StateNotifierProvider<ConnectionStateNotifier, ConnectionState>((ref) {
  final sshService = ref.watch(sshServiceProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return ConnectionStateNotifier(sshService, secureStorage);
});

class ConnectionStateNotifier extends StateNotifier<ConnectionState> {
  final SSHService _sshService;
  // ignore: unused_field - kept for future use
  final SecureStorageService _secureStorage;

  ConnectionStateNotifier(this._sshService, this._secureStorage)
      : super(ConnectionState.disconnected());

  SSHService get sshService => _sshService;

  Future<void> connect(Connection connection,
      {String? password, String? privateKey, String? passphrase}) async {
    state = state.copyWith(
      status: ConnectionStatus.connecting,
      connection: connection,
      errorMessage: null,
    );

    try {
      await _sshService.connect(
        connection,
        password: password,
        privateKey: privateKey,
        passphrase: passphrase,
      );
      state = state.copyWith(status: ConnectionStatus.connected);
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('All authentication methods failed') ||
          errorMsg.contains('Authentication failed')) {
        errorMsg = 'Authentication failed. Check username/password or private key.';
      } else if (errorMsg.contains('Connection refused')) {
        errorMsg = 'Connection refused. SSH server may not be running.';
      } else if (errorMsg.contains('Connection closed before authentication')) {
        errorMsg = 'Connection closed. Check credentials or server firewall.';
      } else if (errorMsg.contains('Connection timed out')) {
        errorMsg = 'Connection timed out. Check host IP address.';
      }
      state = state.copyWith(
        status: ConnectionStatus.error,
        errorMessage: errorMsg,
      );
    }
  }

  Future<void> disconnect() async {
    await _sshService.disconnect();
    state = ConnectionState.disconnected();
  }

  void setError(String message) {
    state = state.copyWith(
      status: ConnectionStatus.error,
      errorMessage: message,
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final terminalSessionProvider = StateNotifierProvider.family<
    TerminalSessionNotifier, TerminalSessionState, String>((ref, sessionId) {
  return TerminalSessionNotifier(sessionId);
});

class TerminalSessionNotifier extends StateNotifier<TerminalSessionState> {
  final String _sessionId;

  TerminalSessionNotifier(this._sessionId)
      : super(TerminalSessionState.disconnected(_sessionId));

  void setConnected() {
    state = TerminalSessionState.connected(_sessionId);
  }

  void setDisconnected() {
    state = TerminalSessionState.disconnected(_sessionId);
  }
}
