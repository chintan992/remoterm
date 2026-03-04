import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class LocalTerminalService {
  Process? _process;
  final _stdoutController = StreamController<List<int>>.broadcast();
  final _stderrController = StreamController<List<int>>.broadcast();

  Stream<List<int>> get stdout => _stdoutController.stream;
  Stream<List<int>> get stderr => _stderrController.stream;

  Future<void> start(String workingDirectory, {String shell = 'bash'}) async {
    try {
      // On Windows, use 'cmd.exe' or 'powershell.exe' if bash isn't available
      String executable = shell;
      List<String> arguments = [];

      if (Platform.isWindows && shell == 'bash') {
        // Try to find bash or fallback to cmd
        executable = 'cmd.exe';
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

      _process!.exitCode.then((code) {
        debugPrint('Local terminal exited with code $code');
      });
    } catch (e) {
      debugPrint('Error starting local terminal: $e');
      rethrow;
    }
  }

  void write(String data) {
    _process?.stdin.write(data);
  }

  void resize(int width, int height) {
    // Standard Dart Process doesn't support PTY resize directly easily
    // This is a limitation without a native PTY library
  }

  Future<void> stop() async {
    _process?.kill();
    _process = null;
  }

  void dispose() {
    stop();
    _stdoutController.close();
    _stderrController.close();
  }
}
