import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

import '../../models/workspace.dart';
import '../../providers/ui_state_provider.dart';
import '../../services/local_terminal_service.dart';
import '../../theme/xterm_theme.dart';

class TerminalGridItem extends ConsumerStatefulWidget {
  final Cubicle cubicle;
  final VoidCallback? onClose;
  final VoidCallback? onExpand;

  const TerminalGridItem({
    super.key,
    required this.cubicle,
    this.onClose,
    this.onExpand,
  });

  @override
  ConsumerState<TerminalGridItem> createState() => _TerminalGridItemState();
}

class _TerminalGridItemState extends ConsumerState<TerminalGridItem> {
  late Terminal _terminal;
  late LocalTerminalService _terminalService;
  final FocusNode _focusNode = FocusNode();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(maxLines: 1000);
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
    try {
      await _terminalService.start(widget.cubicle.path);
      
      _terminalService.stdout.listen((data) {
        _terminal.write(utf8.decode(data));
      });
      
      _terminal.onOutput = (data) {
        _terminalService.write(data);
      };

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      _terminal.write('Error: $e\r\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(uiStateProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(4),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.cubicle.name,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onExpand,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onClose,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Expanded(
            child: Focus(
              focusNode: _focusNode,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.backspace) {
                    _terminalService.write('\x7f');
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                    _terminalService.write('\r');
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.tab) {
                    _terminalService.write('\t');
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: !_isInitialized
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : TerminalView(
                      _terminal,
                      theme: XTermThemeConverter.getXTermTheme(uiState.defaultTerminalTheme),
                      textStyle: TerminalStyle(
                        fontSize: uiState.terminalFontSize * 0.8, // Slightly smaller for grid
                        fontFamily: uiState.defaultFontFamily,
                      ),
                      autoFocus: false,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
