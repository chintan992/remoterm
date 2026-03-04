import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/workspace.dart';
import '../../providers/workspace_provider.dart';
import '../widgets/terminal_grid_item.dart';
import 'cubicle_terminal_screen.dart';

class AiOfficeGridScreen extends ConsumerStatefulWidget {
  final AiOffice office;

  const AiOfficeGridScreen({super.key, required this.office});

  @override
  ConsumerState<AiOfficeGridScreen> createState() => _AiOfficeGridScreenState();
}

class _AiOfficeGridScreenState extends ConsumerState<AiOfficeGridScreen> {
  final List<String> _activeCubicleIds = [];

  @override
  Widget build(BuildContext context) {
    // Re-fetch office from state to get updated cubicle list
    final office = ref.watch(workspaceProvider).offices.firstWhere(
          (o) => o.id == widget.office.id,
          orElse: () => widget.office,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text('Office: ${office.mainProjectPath.split(Platform.pathSeparator).last}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Launch Cubicle',
            onPressed: () => _showLaunchPicker(context, office),
          ),
        ],
      ),
      body: _activeCubicleIds.isEmpty
          ? _buildEmptyGrid(context, office)
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 600,
                mainAxisExtent: 400,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _activeCubicleIds.length,
              itemBuilder: (context, index) {
                final cubicleId = _activeCubicleIds[index];
                final cubicle = office.cubicles.firstWhere((c) => c.id == cubicleId);
                
                return TerminalGridItem(
                  cubicle: cubicle,
                  onClose: () {
                    setState(() {
                      _activeCubicleIds.remove(cubicleId);
                    });
                  },
                  onExpand: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CubicleTerminalScreen(cubicle: cubicle),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyGrid(BuildContext context, AiOffice office) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.grid_view, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No active terminals in this grid'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showLaunchPicker(context, office),
            icon: const Icon(Icons.launch),
            label: const Text('Launch a Cubicle'),
          ),
        ],
      ),
    );
  }

  void _showLaunchPicker(BuildContext context, AiOffice office) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select Cubicle to Launch', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (office.cubicles.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No cubicles created yet. Create one in the Office view.'),
                ),
              ...office.cubicles.map((c) => ListTile(
                    leading: const Icon(Icons.sensor_door_outlined),
                    title: Text(c.name),
                    onTap: () {
                      setState(() {
                        if (!_activeCubicleIds.contains(c.id)) {
                          _activeCubicleIds.add(c.id);
                        }
                      });
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }
}

// Global Platform check helper
class Platform {
  static String get pathSeparator => (const bool.fromEnvironment('dart.library.io')) 
      ? (Uri.base.scheme == 'file' ? (Uri.base.path.contains(':') ? '\\' : '/') : '/') 
      : '/';
}
