import 'dart:convert';
import 'dart:io';
import '../core/app_core.dart';
import 'app_services.dart';

// Responsibilities:
// - Generate timestamped filenames
// - Check available storage space
// - Serialize ProcessedSample list to JSON
// - Save JSON files to Downloads directory
// - Handle write errors gracefully
//
// Enhancements:
// 1. Storage Check: Implement via Android StatFs API (MethodChannel)
// 2. Large Session Optimization: Serialize large sessions (>10K samples) via compute() isolate
// 3. Session Management: Auto-cleanup sessions older than 30 days

class PersistenceService {
  static Future<String?> saveSessionData({
    required List<ProcessedSample> samples,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final filename = _generateFilename(startTime);
      final filePath = await _getDownloadsPath(filename);
      if (filePath == null) return null;

      final jsonData = {
        'session': {
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'sampleCount': samples.length,
        },
        'samples': samples.map((sample) => sample.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
      final file = File(filePath);
      await file.writeAsString(jsonString);

      return filePath;
    } catch (e) {
      return null;
    }
  }

  // Phase 2 Enhancement: Storage check via Android StatFs API
  // Current: Always returns true (assumes sufficient storage)
  // Future: MethodChannel to call Android StatFs for accurate free space check
  // Implementation: platform_channel('storage_check').invokeMethod('getFreeSpace')
  // Threshold: Warn if <100MB free before starting recording
  static Future<bool> hasEnoughStorage() async => true;

  static Future<String> getStorageStatus() async {
    return 'Storage check not implemented';
  }

  static String _generateFilename(DateTime timestamp) {
    return '${timestamp.toMasitekFilename()}.json';
  }

  static Future<String?> _getDownloadsPath(String filename) async {
    try {
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) return null;

      final sessionsPath = '${externalDir.path}/Sessions';
      final sessionsDir = Directory(sessionsPath);

      if (!await sessionsDir.exists()) {
        await sessionsDir.create(recursive: true);
      }

      return '$sessionsPath/$filename';
    } catch (e) {
      return null;
    }
  }
}

class PersistenceException implements Exception {
  final String message;
  PersistenceException(this.message);

  @override
  String toString() => 'PersistenceException: $message';
}
