import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../models/connection.dart';

class SSHException implements Exception {
  final String message;
  final dynamic originalError;

  SSHException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

class SSHService {
  SSHClient? _client;
  SSHSession? _session;
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  Future<void> get done => _client?.done ?? Future.value();

  Future<bool> connect(
    Connection connection, {
    String? password,
    String? privateKey,
    String? passphrase,
  }) async {
    try {
      final socket = await SSHSocket.connect(
        connection.host,
        connection.port,
        timeout: const Duration(seconds: 30),
      );

      if (connection.authMethod == AuthMethod.password) {
        if (password == null || password.isEmpty) {
          await socket.close();
          throw SSHException(
            'Password is required for password authentication',
          );
        }
        _client = SSHClient(
          socket,
          username: connection.username,
          onPasswordRequest: () => password,
        );
      } else {
        if (privateKey == null || privateKey.isEmpty) {
          await socket.close();
          throw SSHException('Private key is required for key authentication');
        }
        try {
          final keyPairs = SSHKeyPair.fromPem(privateKey, passphrase);
          _client = SSHClient(
            socket,
            username: connection.username,
            identities: keyPairs,
          );
        } on SSHException {
          await socket.close();
          rethrow;
        } catch (keyError) {
          await socket.close();
          throw SSHException('Invalid private key format: $keyError', keyError);
        }
      }

      _isConnected = true;
      return true;
    } on SSHAuthFailError catch (e) {
      _isConnected = false;
      throw SSHException(
        'Authentication failed: All authentication methods failed',
        e,
      );
    } on SocketException catch (e) {
      _isConnected = false;
      if (e.message.contains('Connection refused')) {
        throw SSHException(
          'Connection refused. Is SSH server running on ${connection.host}:${connection.port}?',
          e,
        );
      } else if (e.message.contains('Connection timed out')) {
        throw SSHException(
          'Connection timed out. Check if ${connection.host} is reachable.',
          e,
        );
      } else if (e.message.contains('Name or service not known')) {
        throw SSHException('Host not found: ${connection.host}', e);
      }
      throw SSHException('Network error: ${e.message}', e);
    } catch (e) {
      _isConnected = false;
      String errorStr = e.toString();
      if (errorStr.contains('HandshakeException')) {
        throw SSHException(
          'SSH handshake failed. Server may not support SSH protocol.',
          e,
        );
      }
      debugPrint('SSH connect error: $e');
      rethrow;
    }
  }

  Future<SSHSession?> startSession({
    int cols = 80,
    int rows = 24,
    RemoteShell remoteShell = RemoteShell.bash,
  }) async {
    if (_client == null || !_isConnected) {
      return null;
    }

    try {
      // Use execute with the specified shell instead of the default shell
      // This allows users to choose bash, zsh, fish, PowerShell, etc.
      final shellCommand = remoteShell.command;
      debugPrint(
        '[SSH] startSession: remoteShell=${remoteShell.name}, command="$shellCommand"',
      );
      debugPrint('[SSH] startSession: pty cols=$cols, rows=$rows');

      final session = await _client!.execute(
        shellCommand,
        pty: SSHPtyConfig(width: cols, height: rows),
      );
      _session = session;
      debugPrint('[SSH] startSession: session created successfully');
      return session;
    } catch (e) {
      debugPrint('SSH session error: $e');
      return null;
    }
  }

  Future<SftpClient?> sftp() async {
    if (_client == null || !_isConnected) {
      return null;
    }
    try {
      return await _client!.sftp();
    } catch (e) {
      debugPrint('SFTP init error: $e');
      return null;
    }
  }

  Future<ServerSocket?> startLocalForwarding(
    int localPort,
    String targetHost,
    int targetPort,
  ) async {
    if (_client == null || !_isConnected) {
      return null;
    }
    try {
      final serverSocket = await ServerSocket.bind('localhost', localPort);
      serverSocket.listen((clientSocket) async {
        try {
          final forwardChannel = await _client!.forwardLocal(
            targetHost,
            targetPort,
          );

          clientSocket.listen(
            (data) {
              forwardChannel.sink.add(Uint8List.fromList(data));
            },
            onDone: () {
              forwardChannel.sink.close();
            },
            onError: (e) {
              forwardChannel.sink.close();
            },
          );

          forwardChannel.stream.listen(
            (data) {
              clientSocket.add(data);
            },
            onDone: () {
              clientSocket.close();
            },
            onError: (e) {
              clientSocket.close();
            },
          );
        } catch (e) {
          debugPrint('Failed to open forward channel: $e');
          clientSocket.close();
        }
      });

      debugPrint(
        'Port forwarding started: localhost:$localPort -> $targetHost:$targetPort',
      );
      return serverSocket;
    } catch (e) {
      debugPrint('Port forwarding error: $e');
      rethrow;
    }
  }

  Stream<String> get stdoutStream {
    if (_session == null) {
      return const Stream.empty();
    }
    return _session!.stdout.cast<List<int>>().transform(utf8.decoder);
  }

  Stream<String> get stderrStream {
    if (_session == null) {
      return const Stream.empty();
    }
    return _session!.stderr.cast<List<int>>().transform(utf8.decoder);
  }

  void write(String data) {
    if (_session != null && _isConnected) {
      _session!.stdin.add(utf8.encode(data));
    }
  }

  void writeBytes(Uint8List data) {
    if (_session != null && _isConnected) {
      _session!.stdin.add(data);
    }
  }

  Future<void> resize(int cols, int rows) async {
    if (_session != null && _isConnected) {
      try {
        _session!.resizeTerminal(cols, rows, 0, 0);
      } catch (e) {
        debugPrint('SSH resize error: $e');
      }
    }
  }

  Future<void> disconnect() async {
    try {
      _session?.close();
      _client?.close();
    } catch (e) {
      debugPrint('SSH disconnect error: $e');
    } finally {
      _session = null;
      _client = null;
      _isConnected = false;
    }
  }
}
