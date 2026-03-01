import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/connection.dart';
import '../../providers/saved_connections_provider.dart';
import '../widgets/connection_tile.dart';
import '../widgets/group_header.dart';
import '../widgets/connection_context_menu.dart';
import '../widgets/add_connection_dialog.dart';
import 'settings_screen.dart';
import 'terminal_screen.dart';
import 'help_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Set<String> _expandedGroups = {};

  @override
  Widget build(BuildContext context) {
    final connectionsNotifier = ref.watch(savedConnectionsProvider.notifier);
    final groupedConnections = connectionsNotifier.getConnectionsGrouped();

    return Scaffold(
      appBar: AppBar(
        title: const Text('RemoteTerm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: groupedConnections.isEmpty
          ? _buildEmptyState(context)
          : _buildGroupedList(context, ref, groupedConnections),
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
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first SSH connection',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.help_outline),
              label: const Text('Setup Guide'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedList(
      BuildContext context, WidgetRef ref, Map<String, List<Connection>> groupedConnections) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh connection status
      },
      child: ListView.builder(
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
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: connections.map((connection) {
                    return ConnectionTile(
                      connection: connection,
                      onTap: () => _connectToHost(context, ref, connection),
                      onDelete: () => _deleteConnection(context, ref, connection),
                      onEdit: () => _editConnection(context, ref, connection),
                      onLongPress: () => _showContextMenu(context, ref, connection),
                    );
                  }).toList(),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddConnectionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const AddConnectionDialog(),
    );
  }

  void _connectToHost(BuildContext context, WidgetRef ref, Connection connection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TerminalScreen(connection: connection),
      ),
    );
  }

  void _deleteConnection(BuildContext context, WidgetRef ref, Connection connection) {
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
              ref.read(savedConnectionsProvider.notifier).deleteConnection(connection.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editConnection(BuildContext context, WidgetRef ref, Connection connection) {
    showDialog(
      context: context,
      builder: (context) => AddConnectionDialog(connection: connection),
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref, Connection connection) {
    ConnectionContextMenu.show(
      context,
      connection: connection,
      onReconnect: () => _connectToHost(context, ref, connection),
      onDetails: () => _showConnectionDetails(context, connection),
      onEdit: () => _editConnection(context, ref, connection),
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
            _detailRow('Auth Method', connection.authMethod == AuthMethod.password ? 'Password' : 'Private Key'),
            _detailRow('Group', connection.group),
            if (connection.lastConnected != null)
              _detailRow('Last Connected', _formatDateTime(connection.lastConnected!)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _duplicateConnection(BuildContext context, WidgetRef ref, Connection connection) {
    final newConnection = connection.copyWith(
      name: 'Copy of ${connection.name}',
    );
    ref.read(savedConnectionsProvider.notifier).addConnection(newConnection);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created "${newConnection.name}"')),
    );
  }
}
