import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ui_state_provider.dart';
import '../../theme/terminal_themes.dart';
import 'help_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(uiStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Theme'),
            subtitle: Text(_getThemeLabel(uiState.themeMode)),
            onTap: () => _showThemeDialog(context, ref, uiState.themeMode),
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Terminal Font Size'),
            subtitle: Slider(
              value: uiState.terminalFontSize,
              min: 10,
              max: 24,
              divisions: 14,
              label: '${uiState.terminalFontSize.toInt()}px',
              onChanged: (value) {
                ref.read(uiStateProvider.notifier).setFontSize(value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Terminal Theme'),
            subtitle: Text(getThemeDisplayName(uiState.defaultTerminalTheme)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTerminalThemeDialog(
              context,
              ref,
              uiState.defaultTerminalTheme,
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Behavior'),
          ListTile(
            leading: const Icon(Icons.tab),
            title: const Text('Max Tabs'),
            subtitle: Text('${uiState.maxTabs} tabs'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: uiState.maxTabs > 1
                      ? () => ref
                            .read(uiStateProvider.notifier)
                            .setMaxTabs(uiState.maxTabs - 1)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: uiState.maxTabs < 10
                      ? () => ref
                            .read(uiStateProvider.notifier)
                            .setMaxTabs(uiState.maxTabs + 1)
                      : null,
                ),
              ],
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.refresh),
            title: const Text('Auto Reconnect'),
            subtitle: const Text('Automatically reconnect on disconnect'),
            value: uiState.autoReconnect,
            onChanged: (value) {
              ref.read(uiStateProvider.notifier).setAutoReconnect(value);
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Tailscale/Headscale'),
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('Tailscale Server'),
            subtitle: const Text('Configure Tailscale tailnet IP'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showTailscaleDialog(context);
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Help & Support'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Setup Guide'),
            subtitle: const Text('Server setup, Tailscale, troubleshooting'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('RemoteTerm'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'RemoteTerm',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 RemoteTerm',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return ListTile(
              title: Text(_getThemeLabel(mode)),
              leading: Radio<ThemeMode>(
                value: mode,
                // ignore: deprecated_member_use
                groupValue: current,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  if (value != null) {
                    ref.read(uiStateProvider.notifier).setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              onTap: () {
                ref.read(uiStateProvider.notifier).setThemeMode(mode);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showTerminalThemeDialog(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminal Theme'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: terminalThemes.entries.map((entry) {
              return ListTile(
                title: Text(entry.value.name),
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: entry.value.backgroundColor,
                    border: Border.all(
                      color: entry.value.foregroundColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                trailing: current == entry.key
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  ref
                      .read(uiStateProvider.notifier)
                      .setDefaultTerminalTheme(entry.key);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showTailscaleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tailscale Configuration'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Tailscale IP',
            hintText: '100.x.x.x',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
