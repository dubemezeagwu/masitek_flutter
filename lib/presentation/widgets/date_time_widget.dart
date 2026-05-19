import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/extensions/date_time_extensions.dart';


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

    // Calculate seconds until next minute
    final now = DateTime.now();
    final secondsUntilNextMinute = 60 - now.second;

    // Wait until next minute, then update every minute
    Timer(Duration(seconds: secondsUntilNextMinute), () {
      _updateDateTime();
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        _updateDateTime();
      });
    });
  }

  void _updateDateTime() {
    setState(() {
      _currentDateTime = DateTime.now().toFormattedDateTimeString();
    });
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
