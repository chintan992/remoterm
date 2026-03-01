import 'package:xterm/xterm.dart' as xterm;

import 'terminal_themes.dart';

class XTermThemeConverter {
  static xterm.TerminalTheme convertToXTermTheme(TerminalTheme theme) {
    return xterm.TerminalTheme(
      background: theme.backgroundColor,
      foreground: theme.foregroundColor,
      cursor: theme.cursorColor,
      selection: theme.selectionColor,
      searchHitBackground: theme.accentColor,
      searchHitBackgroundCurrent: theme.accentColor.withValues(alpha: 0.5),
      searchHitForeground: theme.foregroundColor,
      black: theme.getAnsiColor(0),
      red: theme.getAnsiColor(1),
      green: theme.getAnsiColor(2),
      yellow: theme.getAnsiColor(3),
      blue: theme.getAnsiColor(4),
      magenta: theme.getAnsiColor(5),
      cyan: theme.getAnsiColor(6),
      white: theme.getAnsiColor(7),
      brightBlack: theme.getAnsiColor(8),
      brightRed: theme.getAnsiColor(9),
      brightGreen: theme.getAnsiColor(10),
      brightYellow: theme.getAnsiColor(11),
      brightBlue: theme.getAnsiColor(12),
      brightMagenta: theme.getAnsiColor(13),
      brightCyan: theme.getAnsiColor(14),
      brightWhite: theme.getAnsiColor(15),
    );
  }

  static xterm.TerminalTheme getXTermTheme(String themeKey) {
    final theme = terminalThemes[themeKey];
    if (theme == null) {
      return convertToXTermTheme(terminalThemes['system']!);
    }
    return convertToXTermTheme(theme);
  }
}
