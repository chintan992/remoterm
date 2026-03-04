import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../models/workspace.dart';
import '../../providers/workspace_provider.dart';
import 'terminal_screen.dart'; // We'll need to adapt this or create a LocalTerminalScreen

class WorkspaceScreen extends ConsumerWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(workspaceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Office Workspaces'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            tooltip: 'Add New Office',
            onPressed: () => _handleCreateOffice(context, ref),
          ),
        ],
      ),
      body: workspaceState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : workspaceState.offices.isEmpty
              ? _buildEmptyState(context, ref)
              : _buildOfficeList(context, ref, workspaceState.offices),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.workspaces_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No AI Offices active'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _handleCreateOffice(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Create your first Office'),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficeList(BuildContext context, WidgetRef ref, List<AiOffice> offices) {
    return ListView.builder(
      itemCount: offices.length,
      itemBuilder: (context, index) {
        final office = offices[index];
        return ExpansionTile(
          leading: const Icon(Icons.folder_special),
          title: Text(office.mainProjectPath.split(Platform.pathSeparator).last),
          subtitle: Text(office.mainProjectPath),
          children: [
            ...office.cubicles.map((cubicle) => ListTile(
                  leading: const Icon(Icons.sensor_door_outlined),
                  title: Text(cubicle.name),
                  subtitle: Text('Created: ${cubicle.createdAt.toString().split('.').first}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _handleDeleteCubicle(context, ref, office, cubicle),
                  ),
                  onTap: () {
                    // TODO: Open local terminal in cubicle.path
                  },
                )),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.blue),
              title: const Text('New Cubicle', style: TextStyle(color: Colors.blue)),
              onTap: () => _handleCreateCubicle(context, ref, office),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleCreateOffice(BuildContext context, WidgetRef ref) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      await ref.read(workspaceProvider.notifier).createOffice(selectedDirectory);
    }
  }

  Future<void> _handleCreateCubicle(BuildContext context, WidgetRef ref, AiOffice office) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Cubicle Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g., bugfix-auth, refactor-ui'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await ref.read(workspaceProvider.notifier).createCubicle(office, name);
    }
  }

  Future<void> _handleDeleteCubicle(BuildContext context, WidgetRef ref, AiOffice office, Cubicle cubicle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cubicle?'),
        content: Text('This will permanently delete the sandbox at ${cubicle.path}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(workspaceProvider.notifier).removeCubicle(office, cubicle);
    }
  }
}
