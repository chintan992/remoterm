import 'dart:io';
import 'package:flutter_riverpod/riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/workspace.dart';
import '../services/workspace_service.dart';

final workspaceServiceProvider = Provider<WorkspaceService>((ref) {
  // This will be overridden in the main.dart with the actual path
  throw UnimplementedError();
});

class WorkspaceState {
  final List<AiOffice> offices;
  final bool isLoading;
  final String? error;

  WorkspaceState({
    this.offices = const [],
    this.isLoading = false,
    this.error,
  });

  WorkspaceState copyWith({
    List<AiOffice>? offices,
    bool? isLoading,
    String? error,
  }) {
    return WorkspaceState(
      offices: offices ?? this.offices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  final WorkspaceService _service;

  WorkspaceNotifier(this._service) : super(WorkspaceState());

  Future<void> createOffice(String projectPath) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final office = await _service.createOffice(projectPath);
      state = state.copyWith(
        offices: [...state.offices, office],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createCubicle(AiOffice office, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cubicle = await _service.createCubicle(office, name);
      
      final updatedOffices = state.offices.map((o) {
        if (o.id == office.id) {
          return o.copyWith(cubicles: [...o.cubicles, cubicle]);
        }
        return o;
      }).toList();

      state = state.copyWith(offices: updatedOffices, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> removeCubicle(AiOffice office, Cubicle cubicle) async {
    state = state.copyWith(isLoading: true, error: null);
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
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final workspaceProvider = StateNotifierProvider<WorkspaceNotifier, WorkspaceState>((ref) {
  final service = ref.watch(workspaceServiceProvider);
  return WorkspaceNotifier(service);
});
