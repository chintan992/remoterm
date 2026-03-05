import 'package:flutter/material.dart';

class AddCubicleDialog extends StatefulWidget {
  final String projectName;
  const AddCubicleDialog({super.key, required this.projectName});

  @override
  State<AddCubicleDialog> createState() => _AddCubicleDialogState();
}

class _AddCubicleDialogState extends State<AddCubicleDialog> {
  final _nameController = TextEditingController();
  final _commandController = TextEditingController();
  String _selectedPreset = 'None';

  final Map<String, String> _presets = {
    'None': '',
    'Claude Code': 'claude dev',
    'Ollama (Llama3)': 'ollama run llama3',
    'Aider': 'aider',
    'Opencode': 'opencode',
    'Kilocode': 'kilocode',
    'Git Status': 'git status',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New Cubicle for ${widget.projectName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Cubicle Name',
                hintText: 'e.g., bugfix-auth-api',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedPreset,
              decoration: const InputDecoration(labelText: 'AI Tool Preset'),
              items: _presets.keys.map((String key) {
                return DropdownMenuItem<String>(value: key, child: Text(key));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPreset = value;
                    if (value != 'None') {
                      _commandController.text = _presets[value]!;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commandController,
              decoration: const InputDecoration(
                labelText: 'Launch Command (Optional)',
                hintText: 'Command to run on startup',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This command will be injected into the terminal stdin upon startup.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'command': _commandController.text,
              });
            }
          },
          child: const Text('Create Cubicle'),
        ),
      ],
    );
  }
}
