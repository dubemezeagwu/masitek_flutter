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
}
