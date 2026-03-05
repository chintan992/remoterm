import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/services.dart';

import '../../providers/ui_state_provider.dart';
import '../../theme/terminal_themes.dart';
import '../../providers/saved_connections_provider.dart';
import '../../services/export_import_service.dart';
import '../../services/key_generation_service.dart';
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
          ListTile(
            leading: const Icon(Icons.font_download),
            title: const Text('Terminal Font Family'),
            subtitle: Text(uiState.defaultFontFamily),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _showFontFamilyDialog(context, ref, uiState.defaultFontFamily),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Behavior'),
          // Show Windows shell option (useful for configuring shell preferences)
          ListTile(
            leading: const Icon(Icons.terminal),
            title: const Text('Windows Shell'),
            subtitle: Text(_getWindowsShellLabel(uiState.windowsShell)),
            onTap: () =>
                _showWindowsShellDialog(context, ref, uiState.windowsShell),
          ),
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
          _buildSectionHeader(context, 'Data Management'),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Export Connections'),
            subtitle: const Text('Save connections to a JSON file'),
            onTap: () => _exportConnections(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import Connections'),
            subtitle: const Text('Load connections from a JSON file'),
            onTap: () => _importConnections(context, ref),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Security'),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('Generate SSH Keypair'),
            subtitle: const Text('Create a new Ed25519 key for authentication'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _generateSshKey(context),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Tailscale/Headscale'),
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('Tailscale Server'),
            subtitle: const Text('Configure Tailscale tailnet IP'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showTailscaleDialog(context, ref);
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

  void _showTailscaleDialog(BuildContext context, WidgetRef ref) {
    final currentIp = ref.read(uiStateProvider).tailscaleIp;
    final controller = TextEditingController(text: currentIp);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tailscale Configuration'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
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
            onPressed: () {
              ref
                  .read(uiStateProvider.notifier)
                  .setTailscaleIp(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  String _getWindowsShellLabel(WindowsShell shell) {
    switch (shell) {
      case WindowsShell.cmd:
        return 'Command Prompt (cmd.exe)';
      case WindowsShell.powershell:
        return 'PowerShell';
      case WindowsShell.pwsh:
        return 'PowerShell Core (pwsh)';
    }
  }

  void _showWindowsShellDialog(
    BuildContext context,
    WidgetRef ref,
    WindowsShell current,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Windows Shell'),
        content: RadioGroup<WindowsShell>(
          groupValue: current,
          onChanged: (value) {
            if (value != null) {
              ref.read(uiStateProvider.notifier).setWindowsShell(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: WindowsShell.values.map((shell) {
              return ListTile(
                title: Text(_getWindowsShellLabel(shell)),
                leading: Radio<WindowsShell>(value: shell),
                onTap: () {
                  ref.read(uiStateProvider.notifier).setWindowsShell(shell);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _exportConnections(BuildContext context, WidgetRef ref) async {
    final connections = ref.read(savedConnectionsProvider);
    if (connections.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No connections to export')));
      return;
    }

    final service = ExportImportService();
    final success = await service.exportConnections(connections);

    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connections exported successfully')),
      );
    }
  }

  Future<void> _importConnections(BuildContext context, WidgetRef ref) async {
    final service = ExportImportService();
    final newConnections = await service.importConnections();

    if (newConnections != null && context.mounted) {
      final notifier = ref.read(savedConnectionsProvider.notifier);
      int importedCount = 0;

      for (final conn in newConnections) {
        // Simple deduplication logic: if name and host match, we might skip, or just add all anyway.
        // Let's add them as new connections (using their original IDs if possible).
        // The provider handles duplicates by replacing if ID exists.
        await notifier.addConnection(conn);
        importedCount++;
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $importedCount connections')),
      );
    }
  }

  Future<void> _generateSshKey(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating keypair...'),
          ],
        ),
      ),
    );

    try {
      final service = KeyGenerationService();
      final result = await service.generateEd25519Key();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        _showGeneratedKeyDialog(context, result);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate key: $e')));
      }
    }
  }

  void _showGeneratedKeyDialog(
    BuildContext context,
    SSHKeyGenerationResult result,
  ) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Force user to acknowledge (they shouldn't lose the private key easily)
      builder: (context) => AlertDialog(
        title: const Text('SSH Keypair Generated'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please copy your private key and store it securely. You will not be able to see it again!',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Public Key (Upload to server):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: SelectableText(
                  result.publicKey,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: result.publicKey));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Public key copied to clipboard'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Public Key'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Private Key (Keep safe):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: SelectableText(
                  result.privateKey,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: result.privateKey));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Private key copied to clipboard'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Private Key'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I have saved my key'),
          ),
        ],
      ),
    );
  }

  void _showFontFamilyDialog(
    BuildContext context,
    WidgetRef ref,
    String currentFont,
  ) {
    final fonts = [
      'monospace',
      'Consolas',
      'Courier New',
      'Fira Code',
      'JetBrains Mono',
      'Source Code Pro',
      'Ubuntu Mono',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminal Font Family'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: fonts.length,
            itemBuilder: (context, index) {
              final font = fonts[index];
              return RadioListTile<String>(
                title: Text(font, style: TextStyle(fontFamily: font)),
                value: font,
                groupValue: currentFont,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(uiStateProvider.notifier)
                        .setDefaultFontFamily(value);
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCustomFontDialog(context, ref, currentFont);
            },
            child: const Text('Custom...'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCustomFontDialog(
    BuildContext context,
    WidgetRef ref,
    String currentFont,
  ) {
    final controller = TextEditingController(text: currentFont);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Font Family'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Font Family Name',
            hintText: 'e.g., "Cascadia Code"',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(uiStateProvider.notifier)
                    .setDefaultFontFamily(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
