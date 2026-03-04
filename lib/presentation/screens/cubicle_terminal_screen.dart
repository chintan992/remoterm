import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../models/workspace.dart';
import '../../providers/ui_state_provider.dart';
import '../../services/local_terminal_service.dart';
import '../../theme/xterm_theme.dart';

class CubicleTerminalScreen extends ConsumerStatefulWidget {
  final Cubicle cubicle;

  const CubicleTerminalScreen({super.key, required this.cubicle});

  @override
  ConsumerState<CubicleTerminalScreen> createState() => _CubicleTerminalScreenState();
}

class _CubicleTerminalScreenState extends ConsumerState<CubicleTerminalScreen> {
  late Terminal _terminal;
  late LocalTerminalService _terminalService;
  bool _isStarting = true;
  String? _error;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(maxLines: 10000);
    _terminalService = LocalTerminalService();
    _startTerminal();
  }

  @override
  void dispose() {
    _terminalService.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _startTerminal() async {
    setState(() {
      _isStarting = true;
      _error = null;
    });

    try {
      await _terminalService.start(widget.cubicle.path);

      _terminalService.stdout.listen((data) {
        _terminal.write(utf8.decode(data));
      });

      _terminalService.stderr.listen((data) {
        _terminal.write(utf8.decode(data));
      });

      _terminal.onOutput = (data) {
        _terminalService.write(data);
      };

      setState(() {
        _isStarting = false;
      });
    } catch (e) {
      setState(() {
        _isStarting = false;
        _error = 'Failed to start local terminal: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(uiStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cubicle: ${widget.cubicle.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startTerminal,
          ),
        ],
      ),
      body: _isStarting
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildTerminalView(uiState),
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
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startTerminal,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalView(UIState uiState) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.backspace) {
            _terminalService.write('\x7f');
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            _terminalService.write('\r');
          } else if (event.logicalKey == LogicalKeyboardKey.tab) {
            _terminalService.write('\t');
          }
        }
        return KeyEventResult.handled;
      },
      child: TerminalView(
        _terminal,
        theme: XTermThemeConverter.getXTermTheme(uiState.defaultTerminalTheme),
        textStyle: TerminalStyle(
          fontSize: uiState.terminalFontSize,
          fontFamily: uiState.defaultFontFamily,
        ),
      ),
    );
  }
}
