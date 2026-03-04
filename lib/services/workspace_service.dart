import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import '../models/workspace.dart';

class WorkspaceException implements Exception {
  final String message;
  WorkspaceException(this.message);
  @override
  String toString() => message;
}

class WorkspaceService {
  final String baseOfficePath;

  WorkspaceService({required this.baseOfficePath});

  Future<AiOffice> createOffice(String projectPath) async {
    final projectName = p.basename(projectPath);
    final officePath = p.join(baseOfficePath, projectName);
    
    final directory = Directory(officePath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return AiOffice(
      mainProjectPath: projectPath,
      officePath: officePath,
    );
  }

  Future<Cubicle> createCubicle(AiOffice office, String name) async {
    final cubiclePath = p.join(office.officePath, name);
    final sourceDir = Directory(office.mainProjectPath);
    final targetDir = Directory(cubiclePath);

    if (await targetDir.exists()) {
      throw WorkspaceException('Cubicle already exists: $name');
    }

    try {
      await _copyDirectory(sourceDir, targetDir);
      return Cubicle(name: name, path: cubiclePath);
    } catch (e) {
      throw WorkspaceException('Failed to create cubicle: $e');
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (var entity in source.list(recursive: false)) {
      if (entity is Directory) {
        // Skip hidden directories like .git or .dart_tool to save time/space
        if (p.basename(entity.path).startsWith('.')) continue;
        
        final newDirectory = Directory(p.join(destination.path, p.basename(entity.path)));
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        await entity.copy(p.join(destination.path, p.basename(entity.path)));
      }
    }
  }

  Future<void> deleteCubicle(Cubicle cubicle) async {
    final dir = Directory(cubicle.path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
