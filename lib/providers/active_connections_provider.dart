import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';

class ActiveConnectionsNotifier extends StateNotifier<List<Connection>> {
  ActiveConnectionsNotifier() : super([]);

  void addConnection(Connection connection) {
    if (!state.any((c) => c.id == connection.id)) {
      state = [...state, connection];
    }
  }

  void removeConnection(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  void clearConnections() {
    state = [];
  }
}

final activeConnectionsProvider =
    StateNotifierProvider<ActiveConnectionsNotifier, List<Connection>>((ref) {
      return ActiveConnectionsNotifier();
    });

final activeTabIndexProvider = StateProvider<int>((ref) => 0);
