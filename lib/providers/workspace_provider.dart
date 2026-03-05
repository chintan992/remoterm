import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workspace.dart';
import '../services/workspace_service.dart';
import 'saved_connections_provider.dart';

final workspaceServiceProvider = Provider<WorkspaceService>((ref) {
  // This is overridden in main.dart
  throw UnimplementedError();
});

class WorkspaceState {
  final List<AiOffice> offices;
  final bool isLoading;
  final String? error;

  WorkspaceState({this.offices = const [], this.isLoading = false, this.error});

  WorkspaceState copyWith({
    List<AiOffice>? offices,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return WorkspaceState(
      offices: offices ?? this.offices,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  Map<String, dynamic> toJson() {
    return {'offices': offices.map((o) => o.toJson()).toList()};
  }

  factory WorkspaceState.fromJson(Map<String, dynamic> json) {
    return WorkspaceState(
      offices:
          (json['offices'] as List<dynamic>?)
              ?.map((o) => AiOffice.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  static const String _storageKey = 'workspace_data';
  final WorkspaceService _service;
  final SharedPreferences _prefs;

  WorkspaceNotifier(this._service, this._prefs) : super(WorkspaceState()) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        state = WorkspaceState.fromJson(json.decode(jsonString));
      } catch (e) {
        debugPrint('Error loading workspace data: $e');
      }
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final jsonString = json.encode(state.toJson());
      await _prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving workspace data: $e');
    }
  }

  Future<void> createOffice(String projectPath) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final office = await _service.createOffice(projectPath);
      state = state.copyWith(
        offices: [...state.offices, office],
        isLoading: false,
      );
      await _saveToPrefs();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createCubicle(
    AiOffice office,
    String name, {
    String? launchCommand,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cubicle = await _service.createCubicle(
        office,
        name,
        launchCommand: launchCommand,
      );

      final updatedOffices = state.offices.map((o) {
        if (o.id == office.id) {
          return o.copyWith(cubicles: [...o.cubicles, cubicle]);
        }
        return o;
      }).toList();

      state = state.copyWith(offices: updatedOffices, isLoading: false);
      await _saveToPrefs();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> syncCubicle(AiOffice office, Cubicle cubicle) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.syncCubicleToMain(office, cubicle);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> removeCubicle(AiOffice office, Cubicle cubicle) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.deleteCubicle(cubicle);

      final updatedOffices = state.offices.map((o) {
        if (o.id == office.id) {
          return o.copyWith(
            cubicles: o.cubicles.where((c) => c.id != cubicle.id).toList(),
          );
        }
        return o;
      }).toList();

      state = state.copyWith(offices: updatedOffices, isLoading: false);
      await _saveToPrefs();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> removeOffice(AiOffice office) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Delete physical directories for all cubicles
      for (final cubicle in office.cubicles) {
        try {
          await _service.deleteCubicle(cubicle);
        } catch (e) {
          debugPrint('Error deleting cubicle ${cubicle.name}: $e');
        }
      }

      state = state.copyWith(
        offices: state.offices.where((o) => o.id != office.id).toList(),
        isLoading: false,
      );
      await _saveToPrefs();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final workspaceProvider =
    StateNotifierProvider<WorkspaceNotifier, WorkspaceState>((ref) {
      final service = ref.watch(workspaceServiceProvider);
      final prefs = ref.watch(sharedPreferencesProvider);
      return WorkspaceNotifier(service, prefs);
    });
