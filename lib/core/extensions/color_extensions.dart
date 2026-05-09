import 'package:flutter/material.dart';

/// Extension methods for Color manipulation.
extension ColorExtension on Color {
  /// Darkens a color by reducing its lightness in HSL color space.
  ///
  /// [amount] must be between 0.0 and 1.0, where:
  /// - 0.0 = no change
  /// - 1.0 = completely black
  Color darken(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }

  /// Lightens a color by increasing its lightness in HSL color space.
  ///
  /// [amount] must be between 0.0 and 1.0, where:
  /// - 0.0 = no change
  /// - 1.0 = completely white
  Color lighten(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightened = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lightened.toColor();
  }
}
