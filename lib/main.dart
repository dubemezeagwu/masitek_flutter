import 'package:flutter/foundation.dart';
import 'ble/app_ble.dart';
import 'core/app_core.dart';
import 'presentation/app_presentation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Debug logging (only in debug builds)
  if (kDebugMode) {
    FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masitek BLE App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const ScanScreen(),
    );
  }
}
