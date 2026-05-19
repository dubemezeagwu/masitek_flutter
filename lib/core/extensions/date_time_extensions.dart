extension DateTimeExtensions on DateTime {
  String get timeOfDay {
    if (hour >= 0 && hour < 12) {
      return "Morning";
    } else if (hour >= 12 && hour < 18) {
      return "Afternoon";
    } else {
      return "Evening";
    }
  }

  String get greeting => "Good $timeOfDay";

  String toMasitekFilename() {
    return 'masitek_'
        '${day.toString().padLeft(2, '0')}_'
        '${month.toString().padLeft(2, '0')}_'
        '${year}_'
        '${hour.toString().padLeft(2, '0')}_'
        '${minute.toString().padLeft(2, '0')}';
  }
}
