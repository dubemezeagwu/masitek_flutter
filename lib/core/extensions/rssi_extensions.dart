import 'package:flutter/material.dart';

extension RssiExtensions on int {
  int get signalStrength {
    if (this >= -50) return 4;
    if (this >= -70) return 3;
    if (this >= -85) return 2;
    if (this >= -100) return 1;
    return 0;
  }

  Color get signalColor {
    switch (signalStrength) {
      case 4:
      case 3:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData get signalIcon {
    switch (signalStrength) {
      case 4:
        return Icons.signal_cellular_4_bar;
      case 3:
        return Icons.signal_cellular_alt;
      case 2:
        return Icons.signal_cellular_alt_2_bar;
      case 1:
        return Icons.signal_cellular_alt_1_bar;
      default:
        return Icons.signal_cellular_connected_no_internet_0_bar;
    }
  }

  String get proximityLabel {
    if (this >= -50) return 'Very Close';
    if (this >= -70) return 'Nearby';
    if (this >= -85) return 'Moderate';
    return 'Far';
  }
}
