import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Guide'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            'Getting Started',
            Icons.play_circle_outline,
            [
              _HelpItem(
                'Install the App',
                'Download and install RemoteTerm on your device from the Play Store or install the APK directly.',
              ),
              _HelpItem(
                'Add a Connection',
                'Tap the + button on the home screen to add your first SSH server.',
              ),
              _HelpItem(
                'Connect',
                'Tap on a saved connection to open the terminal and start working.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Server Setup',
            Icons.dns,
            [
              _HelpItem(
                'Enable SSH on Your Server',
                'Most Linux servers have SSH pre-installed. To check:\n\n'
                    '```bash\n'
                    '# Ubuntu/Debian\n'
                    'sudo apt update\n'
                    'sudo apt install openssh-server\n'
                    'sudo systemctl status ssh\n'
                    '```',
                isCode: true,
              ),
              _HelpItem(
                'Start SSH Service',
                '```bash\n'
                    'sudo systemctl enable ssh\n'
                    'sudo systemctl start ssh\n'
                    '```',
                isCode: true,
              ),
              _HelpItem(
                'Allow SSH Through Firewall',
                '```bash\n'
                    '# Ubuntu (UFW)\n'
                    'sudo ufw allow ssh\n'
                    'sudo ufw enable\n'
                    '\n'
                    '# Or allow specific port\n'
                    'sudo ufw allow 22/tcp\n'
                    '```',
                isCode: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Tailscale VPN Setup',
            Icons.vpn_key,
            [
              _HelpItem(
                'What is Tailscale?',
                'Tailscale is a VPN that creates a secure connection between your devices using private IPs. No port forwarding needed!',
              ),
              _HelpItem(
                '1. Install Tailscale on Your Server',
                '```bash\n'
                    '# Linux (Ubuntu/Debian)\n'
                    'curl -fsSL https://tailscale.com/install.sh | sh\n'
                    '\n'
                    '# Start Tailscale\n'
                    'sudo tailscale up\n'
                    '```\n\n'
                    'Follow the URL shown to log in.',
                isCode: true,
              ),
              _HelpItem(
                '2. Get Your Tailscale IP',
                '```bash\n'
                    'tailscale ip -4\n'
                    '```\n\n'
                    'This returns an IP like: 100.x.x.x',
                isCode: true,
              ),
              _HelpItem(
                '3. Install Tailscale on Mobile',
                'Download Tailscale from:\n'
                    '- Google Play Store (Android)\n'
                    '- App Store (iOS)',
              ),
              _HelpItem(
                '4. Connect in RemoteTerm',
                '1. Open RemoteTerm\n'
                    '2. Tap + to add connection\n'
                    '3. Enter your Tailscale IP (from step 2)\n'
                    '4. Set port to 22\n'
                    '5. Enter your server username\n'
                    '6. Save and connect!',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Platform-Specific Setup',
            Icons.computer,
            [
              _HelpItem(
                'Windows Server',
                '1. Install OpenSSH Server:\n'
                    '   Settings → Apps → Optional Features → Add OpenSSH Server\n\n'
                    '2. Start the service:\n'
                    '   Services → OpenSSH SSH Server → Start\n\n'
                    '3. Allow through firewall (if prompted)',
              ),
              _HelpItem(
                'macOS',
                '1. Enable Remote Login:\n'
                    '   System Settings → General → Sharing → Remote Login\n\n'
                    '2. Allow access for: All users (or select users)\n\n'
                    '3. SSH is now available on port 22',
              ),
              _HelpItem(
                'Linux (General)',
                'Most distributions come with SSH pre-installed.\n\n'
                    '```bash\n'
                    '# Check if SSH is running\n'
                    'systemctl status sshd\n'
                    '\n'
                    '# Install if needed (Debian/Ubuntu)\n'
                    'sudo apt install openssh-server\n'
                    '```',
                isCode: true,
              ),
              _HelpItem(
                'Raspberry Pi',
                '```bash\n'
                    'sudo apt update\n'
                    'sudo apt install openssh-server\n'
                    'sudo raspi-config\n'
                    '# Navigate to: Interface Options → SSH → Enable\n'
                    '```',
                isCode: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Quick Actions',
            Icons.touch_app,
            [
              _HelpItem(
                'Terminal Shortcuts',
                'The Quick Actions bar at the bottom provides:\n\n'
                    '- TAB: Tab completion\n'
                    '- ESC: Escape key\n'
                    '- Ctrl+C: Interrupt process\n'
                    '- Ctrl+D: Logout/EOF\n'
                    '- Arrow keys: Navigate history',
              ),
              _HelpItem(
                'Copy & Paste',
                '- Long press to copy selected text\n'
                    '- Tap to paste from clipboard\n'
                    '- Or use the context menu',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Troubleshooting',
            Icons.help_outline,
            [
              _HelpItem(
                'Connection Refused',
                'Possible causes:\n'
                    '- SSH server not running\n'
                    '- Wrong port (default: 22)\n'
                    '- Firewall blocking connection\n\n'
                    'Fix:\n'
                    '```bash\n'
                    'sudo systemctl start ssh\n'
                    'sudo ufw allow 22/tcp\n'
                    '```',
                isCode: true,
              ),
              _HelpItem(
                'Connection Timed Out',
                'Possible causes:\n'
                    '- Wrong IP address\n'
                    '- Server is offline\n'
                    '- Network firewall\n\n'
                    'Verify with:\n'
                    '```bash\n'
                    'ping <server-ip>\n'
                    '```',
                isCode: true,
              ),
              _HelpItem(
                'Authentication Failed',
                'Check:\n'
                    '- Correct username\n'
                    '- Correct password\n'
                    '- For key auth: public key on server\n\n'
                    '```bash\n'
                    '# Add public key to server\n'
                    'ssh-copy-id user@server\n'
                    '```',
                isCode: true,
              ),
              _HelpItem(
                'Tailscale Not Working',
                '1. Check Tailscale status:\n'
                    '   ```bash\n'
                    '   tailscale status\n'
                    '   ```\n\n'
                    '2. Ensure both devices on same network\n\n'
                    '3. Try:\n'
                    '   ```bash\n'
                    '   sudo tailscale up --verbose\n'
                    '   ```',
                isCode: true,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, IconData icon, List<_HelpItem> items) {
    return Card(
      child: ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        children: items
            .map((item) => _buildHelpItem(context, item))
            .toList(),
      ),
    );
  }

  Widget _buildHelpItem(BuildContext context, _HelpItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          if (item.isCode)
            _buildCodeBlock(context, item.content)
          else
            Text(
              item.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(BuildContext context, String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            code,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                final cleanedCode = code
                    .replaceAll('```bash', '')
                    .replaceAll('```', '')
                    .trim();
                Clipboard.setData(ClipboardData(text: cleanedCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpItem {
  final String title;
  final String content;
  final bool isCode;

  _HelpItem(this.title, this.content, {this.isCode = false});
}
