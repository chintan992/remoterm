import 'dart:io';
import 'package:path/path.dart' as p;
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

  Future<Cubicle> createCubicle(AiOffice office, String name, {String? launchCommand}) async {
    final cubiclePath = p.join(office.officePath, name);
    final sourceDir = Directory(office.mainProjectPath);
    final targetDir = Directory(cubiclePath);

    if (await targetDir.exists()) {
      throw WorkspaceException('Cubicle already exists: $name');
    }

    try {
      await _copyDirectory(sourceDir, targetDir);
      return Cubicle(
        name: name, 
        path: cubiclePath,
        launchCommand: launchCommand,
      );
    } catch (e) {
      throw WorkspaceException('Failed to create cubicle: $e');
    }
  }

  /// Synchronizes changes from the cubicle back to the main project.
  Future<void> syncCubicleToMain(AiOffice office, Cubicle cubicle) async {
    final sourceDir = Directory(cubicle.path);
    final targetDir = Directory(office.mainProjectPath);

    if (!await sourceDir.exists()) {
      throw WorkspaceException('Cubicle directory does not exist: ${cubicle.path}');
    }

    if (!await targetDir.exists()) {
      throw WorkspaceException('Main project directory does not exist: ${office.mainProjectPath}');
    }

    try {
      // Use the same copy logic to push changes back
      await _copyDirectory(sourceDir, targetDir);
    } catch (e) {
      throw WorkspaceException('Failed to sync cubicle to main: $e');
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (var entity in source.list(recursive: false)) {
      final name = p.basename(entity.path);
      
      // Skip common development artifacts and hidden files to keep offices clean
      // and prevent overwriting critical metadata (like .git) during sync.
      if (name.startsWith('.') || 
          name == 'node_modules' || 
          name == 'build' || 
          name == 'target') {
        continue;
      }

      if (entity is Directory) {
        final newDirectory = Directory(p.join(destination.path, name));
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        await entity.copy(p.join(destination.path, name));
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
