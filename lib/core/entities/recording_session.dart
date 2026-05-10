class RecordingSession {
  final DateTime startTime;
  final DateTime endTime;
  final String rawDataFilePath;
  final String videoFilePath;
  final int sampleCount;

  RecordingSession({
    required this.startTime,
    required this.endTime,
    required this.rawDataFilePath,
    required this.videoFilePath,
    required this.sampleCount,
  });

  Map<String, dynamic> toJson() => {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'sampleCount': sampleCount,
      };
}
