import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/connection.dart';
import '../../providers/connection_state_provider.dart';
import '../../providers/saved_connections_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../providers/active_connections_provider.dart';
import '../../services/ssh_service.dart';
import '../../theme/xterm_theme.dart';
import '../../core/render_scheduler.dart';
import '../widgets/quick_actions_bar.dart';

class TerminalHostScreen extends ConsumerStatefulWidget {
  const TerminalHostScreen({super.key});

  @override
  ConsumerState<TerminalHostScreen> createState() => _TerminalHostScreenState();
}

class _TerminalHostScreenState extends ConsumerState<TerminalHostScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _updateTabController(int length, int initialIndex) {
    if (_tabController == null || _tabController!.length != length) {
      _tabController?.dispose();
      _tabController = TabController(
        length: length,
        vsync: this,
        initialIndex: initialIndex < length
            ? initialIndex
            : (length > 0 ? length - 1 : 0),
      );
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(activeTabIndexProvider.notifier).state =
                _tabController!.index;
          });
        }
      });
    } else {
      if (initialIndex != _tabController!.index && initialIndex < length) {
        _tabController!.index = initialIndex;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeConnections = ref.watch(activeConnectionsProvider);
    final activeTabIndex = ref.watch(activeTabIndexProvider);

    if (activeConnections.isEmpty) {
      return const Scaffold(body: Center(child: Text('No active terminals')));
    }

    _updateTabController(activeConnections.length, activeTabIndex);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Terminals'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: activeConnections.map((conn) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(conn.name),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      ref
                          .read(activeConnectionsProvider.notifier)
                          .removeConnection(conn.id);
                    },
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: activeConnections.map((conn) {
          return TerminalTabView(key: ValueKey(conn.id), connection: conn);
        }).toList(),
      ),
    );
  }
}

class TerminalTabView extends ConsumerStatefulWidget {
  final Connection connection;

  const TerminalTabView({super.key, required this.connection});

  @override
  ConsumerState<TerminalTabView> createState() => _TerminalTabViewState();
}

class _TerminalTabViewState extends ConsumerState<TerminalTabView>
    with AutomaticKeepAliveClientMixin {
  late Terminal _terminal;
  late String _sessionId;
  bool _isConnecting = true;
  bool _isConnected = false;
  String? _error;
  bool _isRecording = false;
  File? _logFile;
  StreamSubscription? _stdoutSubscription;
  StreamSubscription? _stderrSubscription;
  final FocusNode _focusNode = FocusNode();
  late TerminalController _terminalController;
  late RenderScheduler _renderScheduler;

  // Each terminal gets its own SSH service instance
  final SSHService _sshService = SSHService();

  // Track last sent dimensions to avoid flooding SSH with resize commands
  int _lastCols = 0;
  int _lastRows = 0;

  bool _isIntentionalDisconnect = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(maxLines: 10000);
    _renderScheduler = RenderScheduler(_terminal);
    _terminalController = TerminalController();
    _sessionId = const Uuid().v4();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _connect();
      }
    });
  }

  @override
  void dispose() {
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();
    _focusNode.dispose();
    _terminalController.dispose();

    _isIntentionalDisconnect = true;

    try {
      _sshService.disconnect();
    } catch (e) {
      debugPrint('Disconnect error during cleanup: $e');
    }

    super.dispose();
  }

  Future<void> _connect() async {
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();

    setState(() {
      _isConnecting = true;
      _isConnected = false;
      _error = null;
    });

    try {
      String? password;
      String? privateKey;
      String? passphrase;

      final secureStorage = ref.read(secureStorageServiceProvider);

      if (widget.connection.authMethod == AuthMethod.password) {
        password = await secureStorage.getCredential(widget.connection.id);

        if (password == null || password.isEmpty) {
          setState(() {
            _isConnecting = false;
            _error =
                'No password saved. Please edit connection to save password.';
          });
          return;
        }
      } else {
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

      await _sshService.connect(
        widget.connection,
        password: password,
        privateKey: privateKey,
        passphrase: passphrase,
      );

      final session = await _sshService.startSession(
        remoteShell: widget.connection.remoteShell,
      );

      if (session != null) {
        _stdoutSubscription = session.stdout.listen((data) {
          final decoded = utf8.decode(data);
          if (_isRecording && _logFile != null) {
            _logFile!.writeAsStringSync(decoded, mode: FileMode.append);
          }
          _renderScheduler.feed(decoded);
        });

        _stderrSubscription = session.stderr.listen((data) {
          final decoded = utf8.decode(data);
          if (_isRecording && _logFile != null) {
            _logFile!.writeAsStringSync(decoded, mode: FileMode.append);
          }
          _renderScheduler.feed(decoded);
        });

        _terminal.onOutput = (data) {
          _sshService.write(data);
          _renderScheduler.flushNow();
        };

        _isConnected = true;
        _isIntentionalDisconnect = false;
        // Notifying system for any required specific UI updates
        ref.read(terminalSessionProvider(_sessionId).notifier).setConnected();

        _sshService.done.then((_) {
          if (mounted &&
              ref.read(uiStateProvider).autoReconnect &&
              !_isIntentionalDisconnect) {
            debugPrint('[Terminal] Connection lost. Auto-reconnecting...');
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) _connect();
            });
          } else {
            if (mounted) {
              setState(() {
                _isConnected = false;
              });
            }
          }
        });

        final initCmd = widget.connection.remoteShell.initCommand;
        if (initCmd != null) {
          await Future.delayed(const Duration(milliseconds: 500));
          _sshService.write(initCmd);
        }

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
    if (width != _lastCols || height != _lastRows) {
      _lastCols = width;
      _lastRows = height;
      _sshService.resize(width, height);
    }
  }

  void _sendSpecialKey(String key) {
    _sshService.write(key);
    _renderScheduler.flushNow();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final uiState = ref.watch(uiStateProvider);

    return Column(
      children: [
        Expanded(
          child: _isConnecting
              ? _buildConnectingState()
              : _error != null
              ? _buildErrorState()
              : _buildTerminalView(uiState),
        ),
        if (_isConnected)
          QuickActionsBar(
            actions: widget.connection.quickActions,
            onAction: _sendSpecialKey,
          ),
      ],
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
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            _sendSpecialKey('\r');
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.tab) {
            _sendSpecialKey('\t');
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
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
            controller: _terminalController,
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
            final selection = _terminalController.selection;
            if (selection != null) {
              final text = _terminal.buffer.getText(selection);
              if (text.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: text));
              }
            }
          },
        ),
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.paste),
            title: Text('Paste'),
            dense: true,
          ),
          onTap: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            if (data?.text != null && data!.text!.isNotEmpty) {
              _terminal.paste(data.text!);
            }
          },
        ),
        PopupMenuItem(
          child: ListTile(
            leading: Icon(
              _isRecording ? Icons.stop_circle : Icons.fiber_manual_record,
              color: _isRecording ? Colors.red : null,
            ),
            title: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            dense: true,
          ),
          onTap: _toggleRecording,
        ),
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.private_connectivity),
            title: Text('Port Forwarding'),
            dense: true,
          ),
          onTap: () {
            // Need to wrap in Future.delayed to allow menu to close first
            Future.delayed(Duration.zero, () {
              _showPortForwardDialog(context);
            });
          },
        ),
      ],
    );
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _logFile = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Recording stopped')));
      }
    } else {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Terminal Log',
        fileName: 'terminal_session.log',
      );

      if (outputFile != null && mounted) {
        setState(() {
          _isRecording = true;
          _logFile = File(outputFile);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording started to $outputFile')),
        );
      }
    }
  }

  void _showPortForwardDialog(BuildContext context) {
    final localPortCtrl = TextEditingController();
    final targetHostCtrl = TextEditingController(text: 'localhost');
    final targetPortCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Port Forwarding'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: localPortCtrl,
              decoration: const InputDecoration(
                labelText: 'Local Port (e.g., 8080)',
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: targetHostCtrl,
              decoration: const InputDecoration(
                labelText: 'Target Host (e.g., localhost)',
              ),
            ),
            TextField(
              controller: targetPortCtrl,
              decoration: const InputDecoration(
                labelText: 'Target Port (e.g., 80)',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final localPort = int.tryParse(localPortCtrl.text);
              final targetPort = int.tryParse(targetPortCtrl.text);
              final targetHost = targetHostCtrl.text;

              if (localPort != null &&
                  targetPort != null &&
                  targetHost.isNotEmpty) {
                Navigator.pop(dialogContext); // close dialog

                try {
                  await _sshService.startLocalForwarding(
                    localPort,
                    targetHost,
                    targetPort,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Forwarding local $localPort to $targetHost:$targetPort',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to start port forwarding: $e'),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}
