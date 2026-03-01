class TerminalSessionState {
  final String sessionId;
  final bool isConnected;
  final int scrollback;
  final DateTime? connectedAt;

  TerminalSessionState({
    required this.sessionId,
    this.isConnected = false,
    this.scrollback = 10000,
    this.connectedAt,
  });

  TerminalSessionState copyWith({
    String? sessionId,
    bool? isConnected,
    int? scrollback,
    DateTime? connectedAt,
  }) {
    return TerminalSessionState(
      sessionId: sessionId ?? this.sessionId,
      isConnected: isConnected ?? this.isConnected,
      scrollback: scrollback ?? this.scrollback,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }

  static TerminalSessionState disconnected(String sessionId) {
    return TerminalSessionState(sessionId: sessionId);
  }

  static TerminalSessionState connected(String sessionId) {
    return TerminalSessionState(
      sessionId: sessionId,
      isConnected: true,
      connectedAt: DateTime.now(),
    );
  }
}
