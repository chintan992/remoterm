import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform;

import '../../models/workspace.dart';
import '../../providers/workspace_provider.dart';
import 'cubicle_terminal_screen.dart';
import 'ai_office_grid_screen.dart';
import '../widgets/add_cubicle_dialog.dart';

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
        final projectName = office.mainProjectPath.split(Platform.pathSeparator).last;
        
        return ExpansionTile(
          leading: const Icon(Icons.folder_special),
          title: Text(projectName),
          subtitle: Text(office.mainProjectPath),
          initiallyExpanded: true,
          trailing: IconButton(
            icon: const Icon(Icons.grid_view),
            tooltip: 'Open Office Grid',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AiOfficeGridScreen(office: office),
                ),
              );
            },
          ),
          children: [
            ...office.cubicles.map((cubicle) => ListTile(
                  leading: const Icon(Icons.sensor_door_outlined),
                  title: Text(cubicle.name),
                  subtitle: Text(cubicle.launchCommand != null && cubicle.launchCommand!.isNotEmpty
                    ? 'AI Tool: ${cubicle.launchCommand}' 
                    : 'Created: ${cubicle.createdAt.toString().split('.').first}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.sync_alt, color: Colors.green),
                        tooltip: 'Sync Changes to Main Project',
                        onPressed: () => _handleSyncCubicle(context, ref, office, cubicle),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _handleDeleteCubicle(context, ref, office, cubicle),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CubicleTerminalScreen(cubicle: cubicle),
                      ),
                    );
                  },
                )),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.blue),
              title: const Text('New Cubicle', style: TextStyle(color: Colors.blue)),
              onTap: () => _handleCreateCubicle(context, ref, office, projectName),
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

  Future<void> _handleCreateCubicle(BuildContext context, WidgetRef ref, AiOffice office, String projectName) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AddCubicleDialog(projectName: projectName),
    );

    if (result != null && result['name'] != null && result['name']!.isNotEmpty) {
      await ref.read(workspaceProvider.notifier).createCubicle(
        office, 
        result['name']!, 
        launchCommand: result['command'],
      );
    }
  }

  Future<void> _handleSyncCubicle(BuildContext context, WidgetRef ref, AiOffice office, Cubicle cubicle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Changes?'),
        content: Text('This will overwrite the main project files at ${office.mainProjectPath} with changes from this cubicle.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sync Now', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(workspaceProvider.notifier).syncCubicle(office, cubicle);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully synced ${cubicle.name} to main project')),
        );
      }
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
