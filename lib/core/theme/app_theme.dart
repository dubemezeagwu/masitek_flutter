import 'package:flutter/material.dart';

/// Centralized theme configuration for the Masitek BLE app.
///
/// Defines:
/// - Color scheme (powder blue accent with black borders)
/// - Typography scale (Material 3)
/// - Custom theme extensions for technical data display
class AppTheme {
  // Powder blue accent color inspired by doc-sync design
  static const Color powderBlue = Color(0xFFADD8E6);
  static const Color powderBlueDark = Color(0xFF87CEEB);
  static const Color cardBorderBlack = Color(0xFF000000);
  static const Color cardShadowBlack = Color(0xFF000000);

  /// Primary theme for the app.
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: powderBlue,
        primary: powderBlueDark,
        secondary: powderBlue,
      ),
      useMaterial3: true,

      // Card theme with rounded corners
      cardTheme: CardThemeData(
        elevation: 0, // We'll use custom borders instead
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: powderBlue,
          foregroundColor: Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // FAB theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: powderBlue,
        foregroundColor: Colors.black87,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Define consistent typography scale
      textTheme: const TextTheme(
        // Large display text (rarely used)
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),

        // Headlines (screen titles, section headers)
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),

        // Titles (card titles, list item titles)
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),

        // Body text (primary content)
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),

        // Labels (buttons, small text)
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),

      // Add custom theme extension for technical data
      extensions: const <ThemeExtension<dynamic>>[
        TechnicalTextTheme(
          hexData: TextStyle(
            fontSize: 16,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2, // Better readability for hex values
          ),
          deviceId: TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.normal,
          ),
          timestamp: TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// Theme extension for technical/monospace text styles.
///
/// Use for:
/// - Hex payload data
/// - Device IDs / MAC addresses
/// - Timestamps
/// - Any other technical data that benefits from monospace font
@immutable
class TechnicalTextTheme extends ThemeExtension<TechnicalTextTheme> {
  final TextStyle hexData;
  final TextStyle deviceId;
  final TextStyle timestamp;

  const TechnicalTextTheme({
    required this.hexData,
    required this.deviceId,
    required this.timestamp,
  });

  @override
  TechnicalTextTheme copyWith({
    TextStyle? hexData,
    TextStyle? deviceId,
    TextStyle? timestamp,
  }) {
    return TechnicalTextTheme(
      hexData: hexData ?? this.hexData,
      deviceId: deviceId ?? this.deviceId,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  TechnicalTextTheme lerp(ThemeExtension<TechnicalTextTheme>? other, double t) {
    if (other is! TechnicalTextTheme) {
      return this;
    }
    return TechnicalTextTheme(
      hexData: TextStyle.lerp(hexData, other.hexData, t)!,
      deviceId: TextStyle.lerp(deviceId, other.deviceId, t)!,
      timestamp: TextStyle.lerp(timestamp, other.timestamp, t)!,
    );
  }
}
