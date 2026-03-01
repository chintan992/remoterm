import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import 'package:uuid/uuid.dart';

import '../../models/connection.dart';
import '../../providers/connection_state_provider.dart';
import '../../providers/saved_connections_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../services/ssh_service.dart';
import '../../theme/xterm_theme.dart';
import '../widgets/quick_actions_bar.dart';

class TerminalScreen extends ConsumerStatefulWidget {
  final Connection connection;

  const TerminalScreen({super.key, required this.connection});

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  late Terminal _terminal;
  late String _sessionId;
  bool _isConnecting = true;
  String? _error;
  StreamSubscription? _stdoutSubscription;
  StreamSubscription? _stderrSubscription;
  final FocusNode _focusNode = FocusNode();

  // Store notifier reference to avoid ref usage after dispose
  ConnectionStateNotifier? _connectionNotifier;
  SSHService? _sshService;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(maxLines: 10000);
    _sessionId = const Uuid().v4();

    // Capture notifier references immediately to avoid dispose issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _connectionNotifier = ref.read(connectionStateProvider.notifier);
        _sshService = _connectionNotifier!.sshService;
        _connect();
      }
    });
  }

  @override
  void dispose() {
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();
    _focusNode.dispose();

    // Use stored references to avoid "ref after dispose" error
    try {
      _connectionNotifier?.disconnect();
    } catch (e) {
      // Ignore errors during cleanup - connection may already be closed
      debugPrint('Disconnect error during cleanup: $e');
    }

    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      String? password;
      String? privateKey;
      String? passphrase;

      // Always try to get credentials from secure storage
      final secureStorage = ref.read(secureStorageServiceProvider);

      if (widget.connection.authMethod == AuthMethod.password) {
        // Try to get saved password
        password = await secureStorage.getCredential(widget.connection.id);

        // If no saved password, show error (would need to re-enter)
        if (password == null || password.isEmpty) {
          setState(() {
            _isConnecting = false;
            _error =
                'No password saved. Please edit connection to save password.';
          });
          return;
        }
      } else {
        // For key auth, get from secure storage
        privateKey = await secureStorage.getPrivateKey(widget.connection.id);
        passphrase = await secureStorage.getPassphrase(widget.connection.id);

        if (privateKey == null || privateKey.isEmpty) {
          setState(() {
            _isConnecting = false;
            _error =
                'No private key saved. Please edit connection to add private key.';
          });
          return;
        }
      }

      await _connectionNotifier!.connect(
        widget.connection,
        password: password,
        privateKey: privateKey,
        passphrase: passphrase,
      );

      final connectionState = ref.read(connectionStateProvider);
      if (connectionState.status == ConnectionStatus.connected) {
        // Use stored SSH service
        final session = await _sshService!.startSession();

        if (session != null) {
          _stdoutSubscription = session.stdout.listen((data) {
            _terminal.write(utf8.decode(data));
          });

          _stderrSubscription = session.stderr.listen((data) {
            _terminal.write(utf8.decode(data));
          });

          _terminal.onOutput = (data) {
            _sshService!.write(data);
          };

          ref.read(terminalSessionProvider(_sessionId).notifier).setConnected();

          // Update lastConnected time
          final updatedConnection = widget.connection.copyWith(
            lastConnected: DateTime.now(),
          );
          ref
              .read(savedConnectionsProvider.notifier)
              .updateConnection(updatedConnection);

          setState(() {
            _isConnecting = false;
          });
        } else {
          setState(() {
            _isConnecting = false;
            _error = 'Failed to start terminal session';
          });
        }
      } else {
        setState(() {
          _isConnecting = false;
          _error = connectionState.errorMessage ?? 'Connection failed';
        });
      }
    } catch (e) {
      String errorMessage = e.toString();

      if (errorMessage.contains('All authentication methods failed') ||
          errorMessage.contains('Authentication failed')) {
        errorMessage =
            'Authentication failed. Check username/password or private key.';
      } else if (errorMessage.contains('Connection refused')) {
        errorMessage =
            'Connection refused. Is SSH server running on the remote host?';
      } else if (errorMessage.contains(
        'Connection closed before authentication',
      )) {
        errorMessage =
            'Connection closed. Check credentials or server firewall.';
      } else if (errorMessage.contains('Connection timed out')) {
        errorMessage = 'Connection timed out. Check the host IP address.';
      } else if (errorMessage.contains('Name or service not known')) {
        errorMessage = 'Host not found. Check the hostname/IP address.';
      } else if (errorMessage.contains('SocketException')) {
        errorMessage = 'Network error. Check your internet connection.';
      }

      setState(() {
        _isConnecting = false;
        _error = errorMessage;
      });
    }
  }

  void _handleResize(int width, int height) {
    _sshService?.resize(width, height);
  }

  void _sendSpecialKey(String key) {
    _sshService?.write(key);
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(uiStateProvider);
    final connectionState = ref.watch(connectionStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.connection.name),
        actions: [
          if (connectionState.status == ConnectionStatus.connecting ||
              _isConnecting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (connectionState.status == ConnectionStatus.connected)
            const Icon(Icons.check_circle, color: Colors.green)
          else if (connectionState.status == ConnectionStatus.error)
            const Icon(Icons.error, color: Colors.red),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _connectionNotifier?.disconnect();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isConnecting
                ? _buildConnectingState()
                : _error != null
                ? _buildErrorState()
                : _buildTerminalView(uiState),
          ),
          if (connectionState.status == ConnectionStatus.connected)
            QuickActionsBar(
              actions: widget.connection.quickActions,
              onAction: _sendSpecialKey,
            ),
        ],
      ),
    );
  }

  Widget _buildConnectingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Connecting to ${widget.connection.host}...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Connection Failed',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _connect,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalView(UIState uiState) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.backspace) {
            _sendSpecialKey('\x7f');
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            _sendSpecialKey('\r');
          } else if (event.logicalKey == LogicalKeyboardKey.tab) {
            _sendSpecialKey('\t');
          }
        }
        return KeyEventResult.handled;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = (constraints.maxWidth / (uiState.terminalFontSize * 0.6))
              .floor();
          final rows =
              (constraints.maxHeight / (uiState.terminalFontSize * 1.2))
                  .floor();

          if (cols > 0 && rows > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _handleResize(cols, rows);
              }
            });
          }

          return TerminalView(
            _terminal,
            theme: XTermThemeConverter.getXTermTheme(
              widget.connection.terminalTheme ?? uiState.defaultTerminalTheme,
            ),
            textStyle: TerminalStyle(
              fontSize: uiState.terminalFontSize,
              fontFamily: uiState.defaultFontFamily,
            ),
            onSecondaryTapDown: (details, offset) {
              _showContextMenu(context, details.globalPosition);
            },
          );
        },
      ),
    );
  }

  void _showContextMenu(BuildContext position, Offset offset) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy,
        offset.dx,
        offset.dy,
      ),
      items: [
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.copy),
            title: Text('Copy'),
            dense: true,
          ),
          onTap: () {
            // Copy functionality would go here
          },
        ),
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.paste),
            title: Text('Paste'),
            dense: true,
          ),
          onTap: () {
            // Paste functionality would go here
          },
        ),
      ],
    );
  }
}
