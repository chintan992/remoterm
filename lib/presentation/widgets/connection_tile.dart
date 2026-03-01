import 'package:flutter/material.dart';

import '../../models/connection.dart';

class ConnectionTile extends StatelessWidget {
  final Connection connection;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onLongPress;

  const ConnectionTile({
    super.key,
    required this.connection,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(connection.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        onDelete();
        return false;
      },
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIndicator(),
            const SizedBox(width: 8),
            CircleAvatar(
              child: Icon(
                Icons.computer,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        title: Text(connection.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${connection.username}@${connection.host}:${connection.port}'),
            if (connection.lastConnected != null)
              Text(
                _formatLastConnected(connection.lastConnected!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              connection.authMethod == AuthMethod.password
                  ? Icons.password
                  : Icons.key,
              size: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
        onLongPress: onLongPress ?? onEdit,
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (connection.isConnected) {
      return const Text('🟢', style: TextStyle(fontSize: 10));
    }
    return const Text('⚪', style: TextStyle(fontSize: 10));
  }

  String _formatLastConnected(DateTime lastConnected) {
    final now = DateTime.now();
    final difference = now.difference(lastConnected);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastConnected.day}/${lastConnected.month}/${lastConnected.year}';
    }
  }
}
