import 'dart:async';
import 'package:flutter/material.dart';

/// Widget displaying current date and time, updated every minute.
///
/// Displays format: "May 12, 2026 • 9:30 AM"
/// Updates automatically every minute to minimize rebuilds.
/// Uses Dart's built-in DateTime - no external packages required.
class DateTimeWidget extends StatefulWidget {
  const DateTimeWidget({super.key});

  @override
  State<DateTimeWidget> createState() => _DateTimeWidgetState();
}

class _DateTimeWidgetState extends State<DateTimeWidget> {
  late String _currentDateTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    // Update every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateDateTime();
    });
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      _currentDateTime = _formatDateTime(now);
    });
  }

  /// Formats DateTime to "May 12, 2026 • 9:30 AM" format.
  String _formatDateTime(DateTime dt) {
    // Month names
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    // Format date: "May 12, 2026"
    final date = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';

    // Format time: "9:30 AM"
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:$minute $period';

    return '$date • $time';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 6),
        Text(
          _currentDateTime,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
