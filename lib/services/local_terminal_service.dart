import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import '../providers/ui_state_provider.dart' show WindowsShell;

class LocalTerminalService {
  Process? _process;
  final _stdoutController = StreamController<List<int>>.broadcast();
  final _stderrController = StreamController<List<int>>.broadcast();

  Stream<List<int>> get stdout => _stdoutController.stream;
  Stream<List<int>> get stderr => _stderrController.stream;

  Future<void> start(
    String workingDirectory, {
    String? sessionId,
    String shell = 'bash',
    String? launchCommand,
    WindowsShell windowsShell = WindowsShell.powershell,
  }) async {
    try {
      String executable = shell;
      List<String> arguments = [];

      // Check if tmux is available for persistence
      bool hasTmux = false;
      if (!Platform.isWindows) {
        try {
          final result = await Process.run('which', ['tmux']);
          hasTmux = result.exitCode == 0;
        } catch (_) {}
      }

      if (hasTmux && sessionId != null) {
        // Use tmux to attach to an existing session or create a new one
        executable = 'tmux';
        arguments = [
          'new-session',
          '-A',
          '-s',
          sessionId,
          '-c',
          workingDirectory,
        ];
      } else if (Platform.isWindows) {
        // Use the selected Windows shell
        switch (windowsShell) {
          case WindowsShell.cmd:
            executable = 'cmd.exe';
            arguments = ['/K', 'cd /d "$workingDirectory"'];
            break;
          case WindowsShell.powershell:
            executable = 'powershell.exe';
            arguments = ['-NoExit', '-Command', 'cd "$workingDirectory"'];
            break;
          case WindowsShell.pwsh:
            executable = 'pwsh.exe';
            arguments = ['-NoExit', '-Command', 'cd "$workingDirectory"'];
            break;
        }
      } else {
        arguments = ['-c', 'cd "$workingDirectory" && exec $shell'];
      }

      _process = await Process.start(
        executable,
        arguments,
        workingDirectory: workingDirectory,
        runInShell: true,
      );

      _process!.stdout.listen((data) {
        _stdoutController.add(data);
      });

      _process!.stderr.listen((data) {
        _stderrController.add(data);
      });

      // If a launch command is provided, send it to stdin after a short delay to ensure shell is ready
      if (launchCommand != null && launchCommand.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          write('$launchCommand\n');
        });
      }

      _process!.exitCode.then((code) {
        debugPrint('Local terminal exited with code $code');
      });
    } catch (e) {
      debugPrint('Error starting local terminal: $e');
      rethrow;
    }
  }

  void write(String data) {
    _process?.stdin.add(utf8.encode(data));
  }

  void stop() {
    _process?.kill();
    _process = null;
  }

  void dispose() {
    stop();
    _stdoutController.close();
    _stderrController.close();
  }
}
