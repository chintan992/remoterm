import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/connection.dart';

class ExportImportService {
  /// Exports the provided connections to a JSON string and saves it using FilePicker.
  /// Note: Passwords and private keys are deliberately NOT exported for security.
  Future<bool> exportConnections(List<Connection> connections) async {
    try {
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Connections',
        fileName: 'remoterm_connections.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (outputFile == null) {
        return false; // User canceled
      }

      final List<Map<String, dynamic>> jsonData = connections
          .map((c) => c.toJson())
          .toList();
      final String jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(jsonData);

      final file = File(outputFile);
      await file.writeAsString(jsonString);
      return true;
    } catch (e) {
      debugPrint('Error exporting connections: $e');
      return false;
    }
  }

  /// Imports connections from a JSON file using FilePicker.
  Future<List<Connection>?> importConnections() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Import Connections',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return null; // User canceled
      }

      final file = File(result.files.single.path!);
      if (!await file.exists()) {
        return null;
      }

      final String jsonString = await file.readAsString();
      final List<dynamic> decodedData = jsonDecode(jsonString);

      final List<Connection> importedConnections = decodedData
          .map((data) => Connection.fromJson(data))
          .toList();

      return importedConnections;
    } catch (e) {
      debugPrint('Error importing connections: $e');
      return null;
    }
  }
}
