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

  String toFormattedDateTimeString() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final date = '${months[month - 1]} $day, $year';

    final hourFormatted = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final minuteFormatted = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final time = '$hourFormatted:$minuteFormatted $period';

    return '$date • $time';
  }
}
