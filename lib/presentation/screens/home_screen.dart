import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/connection.dart';
import '../../providers/saved_connections_provider.dart';
import '../../providers/active_connections_provider.dart';
import '../../providers/connection_state_provider.dart';
import '../../core/shortcuts.dart';
import '../widgets/connection_tile.dart';
import '../widgets/group_header.dart';
import '../widgets/connection_context_menu.dart';
import '../widgets/add_connection_dialog.dart';
import 'settings_screen.dart';
import 'terminal_screen.dart';
import 'sftp_screen.dart';
import 'help_screen.dart';
import 'workspace_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<String> _expandedGroups = {};
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeConns = ref.watch(activeConnectionsProvider);

    if (_selectedIndex == 2 && activeConns.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedIndex == 2) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      });
    }

    return Shortcuts(
      shortcuts: WorkspaceShortcuts.shortcuts,
      child: Actions(
        actions: {
          SwitchCubicleIntent: CallbackAction<SwitchCubicleIntent>(
            onInvoke: (intent) {
              final activeConns = ref.read(activeConnectionsProvider);
              if (activeConns.isNotEmpty) {
                if (_selectedIndex != 2) {
                  setState(() {
                    _selectedIndex = 2; // Switch to Open Tabs view
                  });
                }
                if (intent.index < activeConns.length) {
                  ref.read(activeTabIndexProvider.notifier).state =
                      intent.index;
                }
              }
              return null;
            },
          ),
          ToggleGridIntent: CallbackAction<ToggleGridIntent>(
            onInvoke: (intent) {
              setState(() {
                _selectedIndex = 0; // Switch to SSH (Home)
              });
              return null;
            },
          ),
        },
        child: FocusScope(
          autofocus: true,
          child: Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex > 2
                      ? 0
                      : (_selectedIndex == 2 && activeConns.isEmpty
                            ? 0
                            : _selectedIndex),
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.terminal_outlined),
                      selectedIcon: Icon(Icons.terminal),
                      label: Text('SSH'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.workspaces_outline),
                      selectedIcon: Icon(Icons.workspaces),
                      label: Text('AI Office'),
                    ),
                    if (ref.watch(activeConnectionsProvider).isNotEmpty)
                      const NavigationRailDestination(
                        icon: Icon(Icons.tab_outlined),
                        selectedIcon: Icon(Icons.tab),
                        label: Text('Open Tabs'),
                      ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex > 2
                        ? 0
                        : (_selectedIndex == 2 && activeConns.isEmpty
                              ? 0
                              : _selectedIndex),
                    children: [
                      _buildSSHConnectionsContent(),
                      const WorkspaceScreen(),
                      if (activeConns.isNotEmpty)
                        const TerminalHostScreen()
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSSHConnectionsContent() {
    // Watch the state (list) so the UI rebuilds when connections change
    ref.watch(savedConnectionsProvider);
    final connectionsNotifier = ref.read(savedConnectionsProvider.notifier);

    // Filter connections based on search query
    Map<String, List<Connection>> groupedConnections = {};
    if (_searchQuery.trim().isEmpty) {
      groupedConnections = connectionsNotifier.getConnectionsGrouped();
    } else {
      final allConnections = ref.read(savedConnectionsProvider);
      final query = _searchQuery.trim().toLowerCase();
      final filtered = allConnections.where((c) {
        return c.name.toLowerCase().contains(query) ||
            c.host.toLowerCase().contains(query) ||
            c.username.toLowerCase().contains(query) ||
            c.group.toLowerCase().contains(query);
      }).toList();

      // Group the filtered connections
      for (final conn in filtered) {
        if (!groupedConnections.containsKey(conn.group)) {
          groupedConnections[conn.group] = [];
        }
        groupedConnections[conn.group]!.add(conn);
      }

      // Auto-expand all groups when searching
      for (final group in groupedConnections.keys) {
        _expandedGroups.add(group);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SSH Connections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search connections...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: groupedConnections.isEmpty
                ? (_searchQuery.isNotEmpty
                      ? _buildNoSearchResults()
                      : _buildEmptyState(context))
                : _buildGroupedList(context, ref, groupedConnections),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddConnectionDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.computer_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No connections yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              ),
              icon: const Icon(Icons.help_outline),
              label: const Text('Setup Guide'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    WidgetRef ref,
    Map<String, List<Connection>> groupedConnections,
  ) {
    return ListView.builder(
      itemCount: groupedConnections.length,
      itemBuilder: (context, index) {
        final groupName = groupedConnections.keys.elementAt(index);
        final connections = groupedConnections[groupName]!;
        final isExpanded = _expandedGroups.contains(groupName);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GroupHeader(
              groupName: groupName,
              connectionCount: connections.length,
              isExpanded: isExpanded,
              onToggle: () {
                setState(() {
                  if (isExpanded) {
                    _expandedGroups.remove(groupName);
                  } else {
                    _expandedGroups.add(groupName);
                  }
                });
              },
            ),
            if (isExpanded)
              ...connections.map(
                (connection) => ConnectionTile(
                  connection: connection,
                  onTap: () => _connectToHost(context, ref, connection),
                  onDelete: () => _deleteConnection(context, ref, connection),
                  onEdit: () => _editConnection(context, ref, connection),
                  onLongPress: () => _showContextMenu(context, ref, connection),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showAddConnectionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const AddConnectionDialog(),
    );
  }

  void _connectToHost(
    BuildContext context,
    WidgetRef ref,
    Connection connection,
  ) {
    ref.read(activeConnectionsProvider.notifier).addConnection(connection);

    // Add post frame callback because activeConnectionsProvider needs to update before we rely on it length
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final count = ref.read(activeConnectionsProvider).length;
      ref.read(activeTabIndexProvider.notifier).state = count > 0
          ? count - 1
          : 0;
    });

    setState(() {
      _selectedIndex = 2;
    });
  }

  void _deleteConnection(
    BuildContext context,
    WidgetRef ref,
    Connection connection,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Connection'),
        content: Text('Are you sure you want to delete "${connection.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(savedConnectionsProvider.notifier)
                  .deleteConnection(connection.id);
              ref
                  .read(secureStorageServiceProvider)
                  .deleteAllCredentials(connection.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editConnection(
    BuildContext context,
    WidgetRef ref,
    Connection connection,
  ) {
    showDialog(
      context: context,
      builder: (context) => AddConnectionDialog(connection: connection),
    );
  }

  void _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    Connection connection,
  ) {
    ConnectionContextMenu.show(
      context,
      connection: connection,
      onReconnect: () => _connectToHost(context, ref, connection),
      onDetails: () => _showConnectionDetails(context, connection),
      onEdit: () => _editConnection(context, ref, connection),
      onSftp: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SftpScreen(connection: connection),
          ),
        );
      },
      onDuplicate: () => _duplicateConnection(context, ref, connection),
      onDelete: () => _deleteConnection(context, ref, connection),
    );
  }

  void _showConnectionDetails(BuildContext context, Connection connection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(connection.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Host', connection.host),
            _detailRow('Port', connection.port.toString()),
            _detailRow('Username', connection.username),
            _detailRow(
              'Auth Method',
              connection.authMethod == AuthMethod.password
                  ? 'Password'
                  : 'Private Key',
            ),
            _detailRow('Group', connection.group),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _duplicateConnection(
    BuildContext context,
    WidgetRef ref,
    Connection connection,
  ) async {
    final newConnection = connection.copyWith(
      id: const Uuid().v4(),
      name: '${connection.name} (Copy)',
    );
    await ref
        .read(savedConnectionsProvider.notifier)
        .addConnection(newConnection);

    // Copy credentials from original to duplicated connection
    final secureStorage = ref.read(secureStorageServiceProvider);
    final password = await secureStorage.getCredential(connection.id);
    if (password != null) {
      await secureStorage.saveCredential(newConnection.id, password);
    }
    final privateKey = await secureStorage.getPrivateKey(connection.id);
    if (privateKey != null) {
      await secureStorage.savePrivateKey(newConnection.id, privateKey);
    }
    final passphrase = await secureStorage.getPassphrase(connection.id);
    if (passphrase != null) {
      await secureStorage.savePassphrase(newConnection.id, passphrase);
    }
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No connections match your search',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
