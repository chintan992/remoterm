import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwitchCubicleIntent extends Intent {
  final int index;
  const SwitchCubicleIntent(this.index);
}

class ToggleGridIntent extends Intent {
  const ToggleGridIntent();
}

class WorkspaceShortcuts {
  static Map<ShortcutActivator, Intent> get shortcuts => {
        // Alt + 1 through 9 to switch focus in grid
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit1): const SwitchCubicleIntent(0),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit2): const SwitchCubicleIntent(1),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit3): const SwitchCubicleIntent(2),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit4): const SwitchCubicleIntent(3),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit5): const SwitchCubicleIntent(4),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit6): const SwitchCubicleIntent(5),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit7): const SwitchCubicleIntent(6),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit8): const SwitchCubicleIntent(7),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.digit9): const SwitchCubicleIntent(8),
        
        // Alt + G to toggle grid/fullscreen focus (conceptual)
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.keyG): const ToggleGridIntent(),
      };
}
