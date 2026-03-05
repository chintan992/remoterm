import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../models/connection.dart';
import '../../providers/saved_connections_provider.dart';
import '../../providers/connection_state_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../services/ssh_service.dart';
import '../../theme/terminal_themes.dart';

class AddConnectionDialog extends ConsumerStatefulWidget {
  final Connection? connection;

  const AddConnectionDialog({super.key, this.connection});

  @override
  ConsumerState<AddConnectionDialog> createState() =>
      _AddConnectionDialogState();
}

class _AddConnectionDialogState extends ConsumerState<AddConnectionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _privateKeyController;
  late TextEditingController _passphraseController;
  late TextEditingController _newGroupController;

  AuthMethod _authMethod = AuthMethod.password;
  bool _savePassword = false;
  bool _obscurePassword = true;
  bool _isTesting = false;
  String? _testResult;
  String _selectedGroup = 'Uncategorized';
  String? _selectedTerminalTheme;
  List<String> _selectedQuickActions = List.from(defaultQuickActions);
  bool _showNewGroupField = false;
  RemoteShell _selectedRemoteShell = RemoteShell.bash;
  bool _isLoadingCredentials = false;

  bool get isEditing => widget.connection != null;

  @override
  void initState() {
    super.initState();
    final conn = widget.connection;
    _nameController = TextEditingController(text: conn?.name ?? '');
    _hostController = TextEditingController(text: conn?.host ?? '');
    _portController = TextEditingController(
      text: (conn?.port ?? 22).toString(),
    );
    _usernameController = TextEditingController(text: conn?.username ?? '');
    _passwordController = TextEditingController();
    _privateKeyController = TextEditingController();
    _passphraseController = TextEditingController();
    _newGroupController = TextEditingController();
    _authMethod = conn?.authMethod ?? AuthMethod.password;
    _savePassword = conn?.savePassword ?? false;
    _selectedGroup = conn?.group ?? 'Uncategorized';
    _selectedTerminalTheme = conn?.terminalTheme;
    _selectedQuickActions = conn?.quickActions != null
        ? List.from(conn!.quickActions)
        : List.from(defaultQuickActions);
    _selectedRemoteShell = conn?.remoteShell ?? RemoteShell.bash;

    if (isEditing) {
      _loadSavedCredentials();
    }
  }

  Future<void> _loadSavedCredentials() async {
    setState(() {
      _isLoadingCredentials = true;
    });

    try {
      final secureStorage = ref.read(secureStorageServiceProvider);
      final id = widget.connection!.id;

      final password = await secureStorage.getCredential(id);
      if (password != null && password.isNotEmpty) {
        _passwordController.text = password;
      }

      final privateKey = await secureStorage.getPrivateKey(id);
      if (privateKey != null && privateKey.isNotEmpty) {
        _privateKeyController.text = privateKey;
      }

      final passphrase = await secureStorage.getPassphrase(id);
      if (passphrase != null && passphrase.isNotEmpty) {
        _passphraseController.text = passphrase;
      }
    } catch (e) {
      debugPrint('Failed to load saved credentials: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCredentials = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _privateKeyController.dispose();
    _passphraseController.dispose();
    _newGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Connection' : 'New Connection'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: _isLoadingCredentials
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Connection Name',
                          hintText: 'My Server',
                          prefixIcon: Icon(Icons.label),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildGroupSelector(),
                      const SizedBox(height: 16),
                      _buildTerminalThemeSelector(),
                      const SizedBox(height: 16),
                      _buildQuickActionsSelector(),
                      const SizedBox(height: 16),
                      _buildRemoteShellSelector(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _hostController,
                              decoration: const InputDecoration(
                                labelText: 'Host',
                                hintText: '192.168.1.1',
                                prefixIcon: Icon(Icons.computer),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter host';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _portController,
                              decoration: const InputDecoration(
                                labelText: 'Port',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Port';
                                }
                                final port = int.tryParse(value);
                                if (port == null || port < 1 || port > 65535) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'root',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<AuthMethod>(
                        segments: const [
                          ButtonSegment(
                            value: AuthMethod.password,
                            label: Text('Password'),
                            icon: Icon(Icons.password),
                          ),
                          ButtonSegment(
                            value: AuthMethod.privateKey,
                            label: Text('Private Key'),
                            icon: Icon(Icons.key),
                          ),
                        ],
                        selected: {_authMethod},
                        onSelectionChanged: (Set<AuthMethod> newSelection) {
                          setState(() {
                            _authMethod = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_authMethod == AuthMethod.password) ...[
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          title: const Text('Save Password'),
                          value: _savePassword,
                          onChanged: (value) {
                            setState(() {
                              _savePassword = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _privateKeyController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Private Key',
                            hintText: 'Paste private key here...',
                            alignLabelWithHint: true,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.file_upload),
                              onPressed: _pickPrivateKey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passphraseController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Passphrase (optional)',
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                      ],
                      if (_testResult != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _testResult!.startsWith('Success')
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _testResult!.startsWith('Success')
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: _testResult!.startsWith('Success')
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_testResult!)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: (_isTesting || _isLoadingCredentials)
              ? null
              : _testConnection,
          child: _isTesting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Test'),
        ),
        ElevatedButton(
          onPressed: _isLoadingCredentials ? null : _saveConnection,
          child: Text(isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _pickPrivateKey() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      setState(() {
        _privateKeyController.text = content;
      });
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final connection = _buildConnection();
      final sshService = SSHService();

      final success = await sshService.connect(
        connection,
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
        privateKey: _privateKeyController.text.isNotEmpty
            ? _privateKeyController.text
            : null,
        passphrase: _passphraseController.text.isNotEmpty
            ? _passphraseController.text
            : null,
      );

      await sshService.disconnect();

      setState(() {
        _testResult = success
            ? 'Success! Connection established.'
            : 'Failed to connect. Check credentials.';
      });
    } on Exception catch (e) {
      String errorMsg = _formatError(e.toString());
      setState(() {
        _testResult = errorMsg;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Unexpected error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  String _formatError(String error) {
    if (error.contains('All authentication methods failed') ||
        error.contains('Authentication failed')) {
      return 'Authentication failed. Check username, password, or private key.';
    } else if (error.contains('Connection refused')) {
      return 'Connection refused. Is SSH server running on the remote host?';
    } else if (error.contains('Connection closed before authentication')) {
      return 'Connection closed. Check credentials or server firewall.';
    } else if (error.contains('Connection timed out')) {
      return 'Connection timed out. Check the host IP address.';
    } else if (error.contains('Name or service not known')) {
      return 'Host not found. Check the hostname/IP address.';
    } else if (error.contains('SocketException')) {
      return 'Network error. Check your internet connection.';
    } else if (error.contains('HandshakeException')) {
      return 'SSH handshake failed. Server may not support SSH protocol.';
    }
    // Remove exception prefix for cleaner display
    if (error.startsWith('Exception: ')) {
      return error.substring('Exception: '.length);
    }
    return error;
  }

  Connection _buildConnection() {
    return Connection(
      id: widget.connection?.id,
      name: _nameController.text,
      host: _hostController.text,
      port: int.tryParse(_portController.text) ?? 22,
      username: _usernameController.text,
      authMethod: _authMethod,
      savePassword: _savePassword,
      group: _selectedGroup,
      quickActions: _selectedQuickActions,
      terminalTheme: _selectedTerminalTheme,
      lastConnected: widget.connection?.lastConnected,
      isConnected: widget.connection?.isConnected ?? false,
      remoteShell: _selectedRemoteShell,
    );
  }

  Future<void> _saveConnection() async {
    if (!_formKey.currentState!.validate()) return;

    final connection = _buildConnection();
    final notifier = ref.read(savedConnectionsProvider.notifier);

    if (isEditing) {
      await notifier.updateConnection(connection);
    } else {
      await notifier.addConnection(connection);
    }

    if (_savePassword && _passwordController.text.isNotEmpty) {
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.saveCredential(
        connection.id,
        _passwordController.text,
      );
    }

    if (_privateKeyController.text.isNotEmpty) {
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.savePrivateKey(
        connection.id,
        _privateKeyController.text,
      );
      if (_passphraseController.text.isNotEmpty) {
        await secureStorage.savePassphrase(
          connection.id,
          _passphraseController.text,
        );
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildGroupSelector() {
    final groups = ref.watch(savedConnectionsProvider.notifier).getGroups();
    if (!groups.contains('Uncategorized')) {
      groups.insert(0, 'Uncategorized');
    }
    if (!_showNewGroupField && !groups.contains(_selectedGroup)) {
      groups.insert(0, _selectedGroup);
    }

    if (_showNewGroupField) {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _newGroupController,
              decoration: const InputDecoration(
                labelText: 'New Group Name',
                prefixIcon: Icon(Icons.folder),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              if (_newGroupController.text.isNotEmpty) {
                setState(() {
                  _selectedGroup = _newGroupController.text;
                  _showNewGroupField = false;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _showNewGroupField = false;
                _newGroupController.clear();
              });
            },
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: _selectedGroup,
      decoration: const InputDecoration(
        labelText: 'Group',
        prefixIcon: Icon(Icons.folder),
      ),
      items: [
        ...groups.map(
          (group) => DropdownMenuItem(value: group, child: Text(group)),
        ),
        const DropdownMenuItem(
          value: '__new_group__',
          child: Row(
            children: [
              Icon(Icons.add, size: 18),
              SizedBox(width: 8),
              Text('New Group...'),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        if (value == '__new_group__') {
          setState(() {
            _showNewGroupField = true;
          });
        } else if (value != null) {
          setState(() {
            _selectedGroup = value;
          });
        }
      },
    );
  }

  Widget _buildQuickActionsSelector() {
    final actionLabels = {
      '\t': 'Tab',
      '\x1b': 'Esc',
      '\x03': 'Ctrl+C',
      '\x04': 'Ctrl+D',
      '\x1b[A': '↑ (Up)',
      '\x1b[B': '↓ (Down)',
      '\x1b[D': '← (Left)',
      '\x1b[C': '→ (Right)',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: defaultQuickActions.map((action) {
            final isSelected = _selectedQuickActions.contains(action);
            return FilterChip(
              label: Text(actionLabels[action] ?? action),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedQuickActions.add(action);
                  } else {
                    _selectedQuickActions.remove(action);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTerminalThemeSelector() {
    final uiState = ref.watch(uiStateProvider);
    final currentTheme = _selectedTerminalTheme ?? uiState.defaultTerminalTheme;

    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: currentTheme,
      decoration: const InputDecoration(
        labelText: 'Terminal Theme',
        prefixIcon: Icon(Icons.color_lens),
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('Use Global')),
        ...terminalThemes.entries.map(
          (entry) =>
              DropdownMenuItem(value: entry.key, child: Text(entry.value.name)),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedTerminalTheme = value == '' ? null : value;
        });
      },
    );
  }

  Widget _buildRemoteShellSelector() {
    return DropdownButtonFormField<RemoteShell>(
      initialValue: _selectedRemoteShell,
      decoration: const InputDecoration(
        labelText: 'Remote Shell',
        prefixIcon: Icon(Icons.terminal),
        helperText: 'Shell to use on the remote server',
      ),
      items: RemoteShell.values.map((shell) {
        return DropdownMenuItem(value: shell, child: Text(shell.displayName));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedRemoteShell = value;
          });
        }
      },
    );
  }
}
