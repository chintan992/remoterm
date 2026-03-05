import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';

import '../../models/connection.dart';
import '../../services/ssh_service.dart';
import '../../providers/connection_state_provider.dart';

class SftpScreen extends ConsumerStatefulWidget {
  final Connection connection;

  const SftpScreen({super.key, required this.connection});

  @override
  ConsumerState<SftpScreen> createState() => _SftpScreenState();
}

class _SftpScreenState extends ConsumerState<SftpScreen> {
  final SSHService _sshService = SSHService();
  SftpClient? _sftpClient;
  bool _isConnecting = true;
  String? _error;

  String _currentPath = '.';
  List<SftpName> _files = [];
  bool _isLoadingContent = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _sftpClient?.close();
    _sshService.disconnect();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      String? password;
      String? privateKey;
      String? passphrase;

      final secureStorage = ref.read(secureStorageServiceProvider);

      if (widget.connection.authMethod == AuthMethod.password) {
        password = await secureStorage.getCredential(widget.connection.id);
      } else {
        privateKey = await secureStorage.getPrivateKey(widget.connection.id);
        passphrase = await secureStorage.getPassphrase(widget.connection.id);
      }

      await _sshService.connect(
        widget.connection,
        password: password,
        privateKey: privateKey,
        passphrase: passphrase,
      );

      _sftpClient = await _sshService.sftp();
      if (_sftpClient != null) {
        // dartssh2 SftpClient doesn't have an explicit pwd, we just list '.' and resolve it.
        await _loadDirectory('.');
      } else {
        setState(() {
          _isConnecting = false;
          _error = 'Failed to initialize SFTP subsystem.';
        });
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadDirectory(String path) async {
    if (_sftpClient == null) return;

    setState(() {
      _isLoadingContent = true;
      _error = null;
    });

    try {
      final listedFiles = await _sftpClient!.listdir(path);
      // Sort: Directories first, then alphabetically
      listedFiles.sort((a, b) {
        final aIsDir = a.attr.isDirectory;
        final bIsDir = b.attr.isDirectory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return a.filename.compareTo(b.filename);
      });

      setState(() {
        _currentPath = path;
        _files = listedFiles.where((f) => f.filename != '.').toList();
        _isLoadingContent = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingContent = false;
        _error = 'Error reading directory: $e';
      });
    }
  }

  String _joinPath(String p1, String p2) {
    if (p1.endsWith('/')) {
      return '$p1$p2';
    }
    return '$p1/$p2';
  }

  Future<void> _navigateTo(SftpName item) async {
    if (item.attr.isDirectory) {
      if (item.filename == '..') {
        // Simple dotdot resolution
        final parts = _currentPath.split('/');
        if (parts.isNotEmpty && parts.last != '') {
          parts.removeLast();
          final newPath = parts.isEmpty ? '/' : parts.join('/');
          await _loadDirectory(newPath.isEmpty ? '/' : newPath);
        } else {
          await _loadDirectory('..'); // Fallback if we don't know absolute path
        }
      } else {
        await _loadDirectory(_joinPath(_currentPath, item.filename));
      }
    } else {
      _downloadFile(item);
    }
  }

  Future<void> _downloadFile(SftpName item) async {
    final remotePath = _joinPath(_currentPath, item.filename);
    String? localPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Download File',
      fileName: item.filename,
    );

    if (localPath == null || !mounted) return; // User canceled or unmounted

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Downloading...'),
          ],
        ),
      ),
    );

    try {
      final remoteFile = await _sftpClient!.open(remotePath);
      final localFile = File(localPath);
      final writeStream = localFile.openWrite();

      await for (final chunk in remoteFile.read()) {
        writeStream.add(chunk);
      }

      await writeStream.close();
      await remoteFile.close();

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Downloaded to $localPath')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null || !mounted) return;

    final localPath = result.files.single.path!;
    final fileName = result.files.single.name;
    final remotePath = _joinPath(_currentPath, fileName);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Uploading...'),
          ],
        ),
      ),
    );

    try {
      final localFile = File(localPath);
      final remoteFile = await _sftpClient!.open(
        remotePath,
        mode:
            SftpFileOpenMode.create |
            SftpFileOpenMode.write |
            SftpFileOpenMode.truncate,
      );

      final stream = localFile.openRead().map(
        (chunk) => Uint8List.fromList(chunk),
      );
      await remoteFile.write(stream);
      await remoteFile.close();

      if (!mounted) return;

      if (mounted) {
        Navigator.pop(context); // Close dialog
        await _loadDirectory(_currentPath); // Refresh
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload complete')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SFTP: ${widget.connection.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: (_isConnecting || _sftpClient == null)
                ? null
                : _uploadFile,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (_isConnecting || _sftpClient == null)
                ? null
                : () => _loadDirectory(_currentPath),
          ),
        ],
      ),
      body: _isConnecting
          ? _buildConnectingState()
          : _error != null
          ? _buildErrorState()
          : _buildFileBrowser(),
    );
  }

  Widget _buildConnectingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Starting SFTP session on ${widget.connection.host}...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('SFTP Failed', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_error ?? 'Unknown error', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _sftpClient == null
                  ? _connect
                  : () => _loadDirectory('.'),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileBrowser() {
    if (_isLoadingContent && _files.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          width: double.infinity,
          child: Text(
            'Path: $_currentPath',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        if (_isLoadingContent) const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadDirectory(_currentPath),
            child: ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                final isDir = file.attr.isDirectory;
                return ListTile(
                  leading: Icon(
                    isDir ? Icons.folder : Icons.insert_drive_file,
                    color: isDir ? Colors.blue : null,
                  ),
                  title: Text(file.filename),
                  subtitle: isDir ? null : Text('${file.attr.size ?? 0} bytes'),
                  onTap: () => _navigateTo(file),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
