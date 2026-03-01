import 'package:flutter/material.dart';

import '../../models/connection.dart';

class ConnectionContextMenu extends StatelessWidget {
  final Connection connection;
  final VoidCallback onReconnect;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const ConnectionContextMenu({
    super.key,
    required this.connection,
    required this.onReconnect,
    required this.onDetails,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  static void show(
    BuildContext context, {
    required Connection connection,
    required VoidCallback onReconnect,
    required VoidCallback onDetails,
    required VoidCallback onEdit,
    required VoidCallback onDuplicate,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ConnectionContextMenu(
        connection: connection,
        onReconnect: onReconnect,
        onDetails: onDetails,
        onEdit: onEdit,
        onDuplicate: onDuplicate,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    child: Icon(
                      Icons.computer,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connection.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          '${connection.username}@${connection.host}:${connection.port}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            _buildMenuItem(
              context,
              icon: Icons.refresh,
              label: 'Reconnect',
              onTap: () {
                Navigator.pop(context);
                onReconnect();
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.info_outline,
              label: 'Details',
              onTap: () {
                Navigator.pop(context);
                onDetails();
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.edit,
              label: 'Edit',
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.copy,
              label: 'Duplicate',
              onTap: () {
                Navigator.pop(context);
                onDuplicate();
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.delete,
              label: 'Delete',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(color: color),
      ),
      onTap: onTap,
    );
  }
}
