import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UIState {
  final double terminalFontSize;
  final ThemeMode themeMode;
  final int maxTabs;
  final bool autoReconnect;
  final int activeTabIndex;
  final List<String> openTabs;
  final String defaultTerminalTheme;
  final String defaultFontFamily;

  const UIState({
    this.terminalFontSize = 14.0,
    this.themeMode = ThemeMode.system,
    this.maxTabs = 5,
    this.autoReconnect = true,
    this.activeTabIndex = 0,
    this.openTabs = const [],
    this.defaultTerminalTheme = 'system',
    this.defaultFontFamily = 'monospace',
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
    );
  }
}

final uiStateProvider = StateNotifierProvider<UIStateNotifier, UIState>((ref) {
  return UIStateNotifier();
});

class UIStateNotifier extends StateNotifier<UIState> {
  UIStateNotifier() : super(const UIState());

  void setFontSize(double size) {
    state = state.copyWith(terminalFontSize: size.clamp(10.0, 24.0));
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setMaxTabs(int max) {
    state = state.copyWith(maxTabs: max.clamp(1, 10));
  }

  void setAutoReconnect(bool value) {
    state = state.copyWith(autoReconnect: value);
  }

  void setDefaultTerminalTheme(String theme) {
    state = state.copyWith(defaultTerminalTheme: theme);
  }

  void setDefaultFontFamily(String fontFamily) {
    state = state.copyWith(defaultFontFamily: fontFamily);
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
