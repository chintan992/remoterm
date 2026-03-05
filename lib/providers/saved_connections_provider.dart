import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/connection.dart';

class StorageException implements Exception {
  final String message;
  final dynamic cause;

  StorageException(this.message, [this.cause]);

  @override
  String toString() => message;
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

final savedConnectionsProvider =
    StateNotifierProvider<SavedConnectionsNotifier, List<Connection>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return SavedConnectionsNotifier(prefs);
    });

class SavedConnectionsNotifier extends StateNotifier<List<Connection>> {
  static const String _storageKey = 'saved_connections';

  final SharedPreferences _prefs;

  SavedConnectionsNotifier(this._prefs) : super([]) {
    _loadConnections();
  }

  void _loadConnections() {
    try {
      final jsonString = _prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(jsonString);
        state = jsonList
            .map((item) => Connection.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading connections: $e');
      state = [];
    }
  }

  Future<void> _saveConnections() async {
    try {
      final jsonString = json.encode(state.map((c) => c.toJson()).toList());
      await _prefs.setString(_storageKey, jsonString);
    } catch (e) {
      throw StorageException('Failed to save connections', e);
    }
  }

  Future<bool> addConnection(Connection connection) async {
    try {
      state = [...state, connection];
      await _saveConnections();
      return true;
    } catch (e) {
      debugPrint('Error adding connection: $e');
      // Rollback on error
      state = state.where((c) => c.id != connection.id).toList();
      return false;
    }
  }

  Future<bool> updateConnection(Connection connection) async {
    final previousState = state;
    try {
      state = [
        for (final c in state)
          if (c.id == connection.id) connection else c,
      ];
      await _saveConnections();
      return true;
    } catch (e) {
      state = previousState;
      debugPrint('Error updating connection: $e');
      return false;
    }
  }

  Future<bool> deleteConnection(String id) async {
    try {
      state = state.where((c) => c.id != id).toList();
      await _saveConnections();
      return true;
    } catch (e) {
      debugPrint('Error deleting connection: $e');
      return false;
    }
  }

  Connection? getConnectionById(String id) {
    try {
      return state.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  List<String> getGroups() {
    final groups = state.map((c) => c.group).toSet().toList();
    groups.sort((a, b) {
      if (a == 'Uncategorized') return 1;
      if (b == 'Uncategorized') return -1;
      return a.compareTo(b);
    });
    return groups;
  }

  List<Connection> getConnectionsByGroup(String group) {
    return state.where((c) => c.group == group).toList();
  }

  Map<String, List<Connection>> getConnectionsGrouped() {
    final grouped = <String, List<Connection>>{};
    for (final connection in state) {
      final group = connection.group;
      grouped.putIfAbsent(group, () => []).add(connection);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 'Uncategorized') return 1;
        if (b == 'Uncategorized') return -1;
        return a.compareTo(b);
      });

    return {for (var key in sortedKeys) key: grouped[key]!};
  }
}
