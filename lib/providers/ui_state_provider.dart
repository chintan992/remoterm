import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'saved_connections_provider.dart';

enum WindowsShell { cmd, powershell, pwsh }

class UIState {
  final double terminalFontSize;
  final ThemeMode themeMode;
  final int maxTabs;
  final bool autoReconnect;
  final int activeTabIndex;
  final List<String> openTabs;
  final String defaultTerminalTheme;
  final String defaultFontFamily;
  final WindowsShell windowsShell;
  final String tailscaleIp;

  const UIState({
    this.terminalFontSize = 14.0,
    this.themeMode = ThemeMode.system,
    this.maxTabs = 5,
    this.autoReconnect = true,
    this.activeTabIndex = 0,
    this.openTabs = const [],
    this.defaultTerminalTheme = 'system',
    this.defaultFontFamily = 'monospace',
    this.windowsShell = WindowsShell.powershell,
    this.tailscaleIp = '',
  });

  UIState copyWith({
    double? terminalFontSize,
    ThemeMode? themeMode,
    int? maxTabs,
    bool? autoReconnect,
    int? activeTabIndex,
    List<String>? openTabs,
    String? defaultTerminalTheme,
    String? defaultFontFamily,
    WindowsShell? windowsShell,
    String? tailscaleIp,
  }) {
    return UIState(
      terminalFontSize: terminalFontSize ?? this.terminalFontSize,
      themeMode: themeMode ?? this.themeMode,
      maxTabs: maxTabs ?? this.maxTabs,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      openTabs: openTabs ?? this.openTabs,
      defaultTerminalTheme: defaultTerminalTheme ?? this.defaultTerminalTheme,
      defaultFontFamily: defaultFontFamily ?? this.defaultFontFamily,
      windowsShell: windowsShell ?? this.windowsShell,
      tailscaleIp: tailscaleIp ?? this.tailscaleIp,
    );
  }
}

final uiStateProvider = StateNotifierProvider<UIStateNotifier, UIState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UIStateNotifier(prefs);
});

class UIStateNotifier extends StateNotifier<UIState> {
  static const _prefix = 'ui_';
  final SharedPreferences _prefs;

  UIStateNotifier(this._prefs) : super(const UIState()) {
    _load();
  }

  void _load() {
    final fontSize = _prefs.getDouble('${_prefix}fontSize');
    final themeModeIndex = _prefs.getInt('${_prefix}themeMode');
    final maxTabs = _prefs.getInt('${_prefix}maxTabs');
    final autoReconnect = _prefs.getBool('${_prefix}autoReconnect');
    final terminalTheme = _prefs.getString('${_prefix}terminalTheme');
    final fontFamily = _prefs.getString('${_prefix}fontFamily');
    final windowsShellIndex = _prefs.getInt('${_prefix}windowsShell');
    final tailscaleIp = _prefs.getString('${_prefix}tailscaleIp');

    state = UIState(
      terminalFontSize: fontSize ?? 14.0,
      themeMode: themeModeIndex != null
          ? ThemeMode.values[themeModeIndex]
          : ThemeMode.system,
      maxTabs: maxTabs ?? 5,
      autoReconnect: autoReconnect ?? true,
      defaultTerminalTheme: terminalTheme ?? 'system',
      defaultFontFamily: fontFamily ?? 'monospace',
      windowsShell: windowsShellIndex != null
          ? WindowsShell.values[windowsShellIndex]
          : WindowsShell.powershell,
      tailscaleIp: tailscaleIp ?? '',
    );
  }

  Future<void> _save() async {
    await _prefs.setDouble('${_prefix}fontSize', state.terminalFontSize);
    await _prefs.setInt('${_prefix}themeMode', state.themeMode.index);
    await _prefs.setInt('${_prefix}maxTabs', state.maxTabs);
    await _prefs.setBool('${_prefix}autoReconnect', state.autoReconnect);
    await _prefs.setString(
      '${_prefix}terminalTheme',
      state.defaultTerminalTheme,
    );
    await _prefs.setString('${_prefix}fontFamily', state.defaultFontFamily);
    await _prefs.setInt('${_prefix}windowsShell', state.windowsShell.index);
    await _prefs.setString('${_prefix}tailscaleIp', state.tailscaleIp);
  }

  void setFontSize(double size) {
    state = state.copyWith(terminalFontSize: size.clamp(10.0, 24.0));
    _save();
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _save();
  }

  void setMaxTabs(int max) {
    state = state.copyWith(maxTabs: max.clamp(1, 10));
    _save();
  }

  void setAutoReconnect(bool value) {
    state = state.copyWith(autoReconnect: value);
    _save();
  }

  void setDefaultTerminalTheme(String theme) {
    state = state.copyWith(defaultTerminalTheme: theme);
    _save();
  }

  void setDefaultFontFamily(String fontFamily) {
    state = state.copyWith(defaultFontFamily: fontFamily);
    _save();
  }

  void setWindowsShell(WindowsShell shell) {
    state = state.copyWith(windowsShell: shell);
    _save();
  }

  void setTailscaleIp(String ip) {
    state = state.copyWith(tailscaleIp: ip);
    _save();
  }

  void setActiveTab(int index) {
    if (index >= 0 && index < state.openTabs.length) {
      state = state.copyWith(activeTabIndex: index);
    }
  }

  void addTab(String sessionId) {
    if (state.openTabs.length < state.maxTabs) {
      state = state.copyWith(
        openTabs: [...state.openTabs, sessionId],
        activeTabIndex: state.openTabs.length,
      );
    }
  }

  void removeTab(String sessionId) {
    final newTabs = state.openTabs.where((id) => id != sessionId).toList();
    final newIndex = state.activeTabIndex >= newTabs.length
        ? newTabs.isEmpty
              ? 0
              : newTabs.length - 1
        : state.activeTabIndex;
    state = state.copyWith(openTabs: newTabs, activeTabIndex: newIndex);
  }

  void closeAllTabs() {
    state = state.copyWith(openTabs: [], activeTabIndex: 0);
  }
}
