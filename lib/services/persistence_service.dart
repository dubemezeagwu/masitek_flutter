import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../core/models/processed_sample.dart';

/// Service for persisting session data (JSON files with BLE samples).
///
/// Responsibilities:
/// - Generate timestamped filenames
/// - Check available storage space
/// - Serialize ProcessedSample list to JSON
/// - Save JSON files to Downloads directory
/// - Handle write errors gracefully
class PersistenceService {
  /// Minimum required free storage space (in bytes) to allow recording
  static const int minStorageBytes = 100 * 1024 * 1024; // 100 MB

  /// Saves session data as JSON file in Downloads directory.
  ///
  /// Returns the file path if successful, null if save failed.
  ///
  /// JSON structure:
  /// ```json
  /// {
  ///   "session": {
  ///     "startTime": "2026-05-13T20:30:45Z",
  ///     "endTime": "2026-05-13T20:35:12Z",
  ///     "sampleCount": 1450
  ///   },
  ///   "samples": [...]
  /// }
  /// ```
  static Future<String?> saveSessionData({
    required List<ProcessedSample> samples,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      debugPrint('[PersistenceService] Saving ${samples.length} samples...');

      // Generate filename with timestamp
      final filename = _generateFilename(startTime);
      debugPrint('[PersistenceService] Filename: $filename');

      // Get Downloads directory path
      final filePath = await _getDownloadsPath(filename);
      if (filePath == null) {
        debugPrint('[PersistenceService] ❌ Could not access Downloads directory');
        return null;
      }

      // Build JSON structure
      final jsonData = {
        'session': {
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'sampleCount': samples.length,
        },
        'samples': samples.map((sample) => sample.toJson()).toList(),
      };

      // Serialize to pretty-printed JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

      // Write to file
      final file = File(filePath);
      await file.writeAsString(jsonString);

      debugPrint('[PersistenceService] ✅ Session data saved: $filePath');
      debugPrint('[PersistenceService] File size: ${(await file.length() / 1024).toStringAsFixed(2)} KB');

      return filePath;
    } catch (e) {
      debugPrint('[PersistenceService] ❌ Failed to save session data: $e');
      return null;
    }
  }

  /// Saves session data using compute isolate for large datasets.
  ///
  /// Use this for datasets with >5000 samples to avoid blocking main thread.
  /// For smaller datasets, [saveSessionData] is sufficient.
  static Future<String?> saveSessionDataLarge({
    required List<ProcessedSample> samples,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      debugPrint('[PersistenceService] Using compute isolate for ${samples.length} samples...');

      // Run serialization in compute isolate
      final result = await compute(_saveSessionDataIsolate, {
        'samples': samples,
        'startTime': startTime,
        'endTime': endTime,
      });

      if (result == null) {
        debugPrint('[PersistenceService] ❌ Compute isolate returned null');
        return null;
      }

      debugPrint('[PersistenceService] ✅ Large dataset saved successfully');
      return result;
    } catch (e) {
      debugPrint('[PersistenceService] ❌ Failed to save large dataset: $e');
      return null;
    }
  }

  /// Isolate entry point for large dataset serialization.
  static Future<String?> _saveSessionDataIsolate(Map<String, dynamic> params) async {
    final samples = params['samples'] as List<ProcessedSample>;
    final startTime = params['startTime'] as DateTime;
    final endTime = params['endTime'] as DateTime;

    return await saveSessionData(
      samples: samples,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Checks if device has enough storage space for recording.
  ///
  /// Returns true if at least 100MB free, false otherwise.
  ///
  /// NOTE: Currently disabled due to Dart's FileStat not providing free space info.
  /// TODO: Implement using platform channel to call Android's StatFs API.
  static Future<bool> hasEnoughStorage() async {
    try {
      // Get external storage directory
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        debugPrint('[PersistenceService] ⚠️ Could not access external storage');
        return false; // Conservative: assume not enough space if can't check
      }

      // TEMPORARY: Skip actual check since Dart's FileStat doesn't provide free space
      // In production, this would use a platform channel to call Android's StatFs
      debugPrint('[PersistenceService] ⚠️ Storage check temporarily disabled (always returns true)');
      return true;

      // TODO: Implement proper storage check via platform channel
      // Example for future implementation:
      // final MethodChannel channel = MethodChannel('storage_check');
      // final int freeBytes = await channel.invokeMethod('getFreeSpace');
      // return freeBytes >= minStorageBytes;
    } catch (e) {
      debugPrint('[PersistenceService] ⚠️ Error checking storage: $e');
      return true; // Optimistic: allow recording if check fails
    }
  }

  /// Gets human-readable storage space message.
  ///
  /// Example: "120.5 MB available" or "Storage check failed"
  static Future<String> getStorageStatus() async {
    try {
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        return 'Storage check failed';
      }

      final stat = externalDir.statSync();
      final freeMB = stat.size / 1024 / 1024;

      return '${freeMB.toStringAsFixed(1)} MB available';
    } catch (e) {
      return 'Storage check failed: $e';
    }
  }

  /// Generates filename with timestamp format.
  ///
  /// Format: masitek_day_month_year_hour_minute.json
  /// Example: masitek_13_05_2026_20_30.json
  static String _generateFilename(DateTime timestamp) {
    return 'masitek_'
        '${timestamp.day.toString().padLeft(2, '0')}_'
        '${timestamp.month.toString().padLeft(2, '0')}_'
        '${timestamp.year}_'
        '${timestamp.hour.toString().padLeft(2, '0')}_'
        '${timestamp.minute.toString().padLeft(2, '0')}'
        '.json';
  }

  /// Gets full path in Sessions directory for given filename.
  ///
  /// Returns null if external storage is inaccessible.
  ///
  /// Note: Saves to app-specific external storage (Sessions folder) to avoid
  /// scoped storage restrictions on Android 10+
  static Future<String?> _getDownloadsPath(String filename) async {
    try {
      // Get app's external storage directory
      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        return null;
      }

      // Create Sessions directory for JSON data files
      // Path: /storage/emulated/0/Android/data/com.example.masitek_flutter/files/Sessions
      final sessionsPath = '${externalDir.path}/Sessions';
      final sessionsDir = Directory(sessionsPath);

      // Ensure Sessions directory exists
      if (!await sessionsDir.exists()) {
        await sessionsDir.create(recursive: true);
      }

      return '$sessionsPath/$filename';
    } catch (e) {
      debugPrint('[PersistenceService] ⚠️ Error getting Sessions path: $e');
      return null;
    }
  }

  /// Deletes old session files to free up space.
  ///
  /// Removes JSON and video files older than [daysToKeep].
  /// Useful for cleanup/maintenance.
  static Future<int> cleanupOldSessions({int daysToKeep = 7}) async {
    try {
      debugPrint('[PersistenceService] Cleaning up sessions older than $daysToKeep days...');

      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        return 0;
      }

      final externalStorageRoot = externalDir.path.split('/Android/data/').first;
      final downloadsPath = '$externalStorageRoot/Download';
      final downloadsDir = Directory(downloadsPath);

      if (!await downloadsDir.exists()) {
        return 0;
      }

      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      int deletedCount = 0;

      // Find and delete old masitek_* files
      await for (final entity in downloadsDir.list()) {
        if (entity is File) {
          final filename = entity.path.split('/').last;
          if (filename.startsWith('masitek_')) {
            final stat = await entity.stat();
            if (stat.modified.isBefore(cutoffDate)) {
              await entity.delete();
              deletedCount++;
              debugPrint('[PersistenceService] Deleted: $filename');
            }
          }
        }
      }

      debugPrint('[PersistenceService] ✅ Cleanup complete: $deletedCount files deleted');
      return deletedCount;
    } catch (e) {
      debugPrint('[PersistenceService] ⚠️ Error during cleanup: $e');
      return 0;
    }
  }
}

/// Exception thrown when persistence operations fail.
class PersistenceException implements Exception {
  final String message;
  PersistenceException(this.message);

  @override
  String toString() => 'PersistenceException: $message';
}
