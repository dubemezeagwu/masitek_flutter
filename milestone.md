# Masitek Flutter App - Development Milestones

**Last Updated:** 2026-05-07
**Status:** Planning Phase
**Target Completion:** 90% by 2026-05-20 (2 weeks)

---

## Development Philosophy

**Approach:** Vertical slices - each milestone is a **complete, testable feature** with visual feedback.

**Testing Strategy:** After each milestone, run on Infinix X652A (Android 9, API 28).

**Focus:** Android only (iOS considerations deferred).

**Edge Cases:** Handled inline with related features (not deferred to end).

---

## Git Workflow & Branching Strategy

### Branch Structure

**Solo Project - Two-Branch Model:**

```
git merge --no-ff dev
```

```
main (production-ready code)
  └── dev (active development)
```

**Branch Purposes:**
- **`main`**: Clean, stable, milestone-complete code. Only merge when a milestone is 100% done and tested.
- **`dev`**: Active development branch. All coding, testing, debugging happens here.

**Why not feature branches?**
- Solo project (no parallel work)
- Milestones are sequential (can't start M7 before M6)
- Simpler workflow (less branch management overhead)

---

### Development Workflow

#### Step 1: Initial Setup

```bash
# Create dev branch from main
git checkout -b dev

# Push dev branch to remote
git push -u origin dev
```

#### Step 2: Work on Milestone

```bash
# Ensure you're on dev
git checkout dev

# Work on code (e.g., Milestone 3: BLE Scanning)
# ... make changes, test on device ...

# Commit frequently with descriptive messages
git add .
git commit -m "feat: implement BLE scanning with permission handling

- Add permission_service.dart with SDK-branched logic
- Implement scan functionality in ble_service.dart
- Update scan_screen.dart to display discovered devices
- Add scan rate limiting (max 5/30s)

Milestone 3 - BLE Scanning (in progress)"

# Push to dev branch
git push origin dev
```

#### Step 3: Complete Milestone

```bash
# Final commit for milestone
git add .
git commit -m "feat: complete Milestone 3 - BLE Scanning

- All edge cases handled (permissions, rate limiting)
- Tested on Infinix X652A (Android 9)
- Deliverables verified:
  ✅ Device list populates with NUS-Py
  ✅ Permission handling graceful
  ✅ Scan rate limiting enforced

Status: Ready for merge to main"

git push origin dev
```

#### Step 4: Merge to Main (After Milestone Complete)

**RECOMMENDED: Merge with `--no-ff` (no fast-forward)**

```bash
# Switch to main
git checkout main

# Pull latest (if working across machines)
git pull origin main

# Merge dev with no fast-forward (preserves milestone boundary)
git merge --no-ff dev -m "Merge Milestone 3: BLE Scanning + Permission Handling

Deliverables:
- BLE device scanning functional
- SDK-branched permissions (Android 6-11 vs 12+)
- Scan rate limiting (5/30s)
- Error handling (BLE off, permissions denied)

Tested on: Infinix X652A (Android 9, API 28)
Duration: 4 hours
Status: ✅ Complete"

# Push main
git push origin main

# Continue development on dev
git checkout dev
```

**Result:** Git history shows clear milestone boundaries:

```
main:  M1 ──────── M3 ──────── M5 ──────── M7
              ╱          ╱          ╱
dev:   M1 ─ M2 ─ M3 ─ M4 ─ M5 ─ M6 ─ M7 ─ M8
         └─ commits ─┘
```

---

### Commit Message Format

**Standard Format:**

```
<type>: <short summary> (max 72 chars)

<detailed description>
- Bullet points for multiple changes
- Include technical decisions if relevant

Milestone <N> - <Name> (<status>)
```

**Types:**
- `feat:` New feature (e.g., "feat: implement live chart with dual series")
- `fix:` Bug fix (e.g., "fix: handle malformed BLE payloads")
- `refactor:` Code restructure (e.g., "refactor: extract parser to utility")
- `docs:` Documentation (e.g., "docs: update README with BLE server setup")
- `test:` Testing (e.g., "test: verify reconnection logic")
- `chore:` Tooling/config (e.g., "chore: add Proguard rules")

**Examples:**

```bash
# Feature commit
git commit -m "feat: add worker isolate for data processing

- Create worker_isolate.dart with persistent isolate
- Initialize QuickJS engine for scripting
- Parse payloads off main thread
- Forward processed samples to chart provider

Milestone 7 - Worker Isolate (in progress)"

# Bug fix commit
git commit -m "fix: prevent crash on malformed BLE payload

- Add try-catch in payload parser
- Log hex dump for debugging
- Increment malformed counter in chart provider
- Skip invalid samples instead of crashing

Milestone 5 - Data Parsing"

# Documentation commit
git commit -m "docs: add git workflow section to milestone.md

- Define two-branch strategy (main + dev)
- Document merge vs rebase decision (using merge --no-ff)
- Provide commit message templates

Planning Phase"
```

---

### When to Merge to Main

**Merge Criteria (ALL must be met):**
1. ✅ All milestone deliverables complete
2. ✅ Tested on physical device (Infinix X652A)
3. ✅ No crashes or critical bugs
4. ✅ Code formatted (`dart format .`)
5. ✅ Linter passes (`flutter analyze`)
6. ✅ Milestone status updated in `milestone.md`

**Merge Frequency:**
- After each completed milestone (11 merges total)
- Optionally: Mid-milestone if you want to save stable checkpoints

**Don't merge if:**
- ❌ Feature partially working
- ❌ Known bugs exist
- ❌ Haven't tested on device
- ❌ Code breaks existing functionality

---

### Rebase vs Merge: Final Verdict

**Use Merge (`--no-ff`) for this project because:**

| Factor | Merge --no-ff | Rebase |
|--------|---------------|--------|
| **History clarity** | Clear milestone boundaries | Linear but loses context |
| **Code review** | Easy to see feature chunks | Harder to see logical units |
| **Revert ability** | Easy (`git revert -m`) | Harder (find commit range) |
| **Assessment context** | Shows organized development | Shows commit stream |
| **Industry standard** | Yes (most teams use merge) | Common but situational |
| **Solo project** | ✅ Perfect for milestones | ✅ Works but loses info |

**Example: What Przemek sees in git log:**

**With Merge:**
```
* Merge Milestone 7: Worker Isolate + Scripting  [main]
|\
| * feat: add dual-series chart rendering
| * feat: integrate QuickJS for script execution
| * feat: create persistent worker isolate
|/
* Merge Milestone 6: Live Chart Integration
```

**With Rebase:**
```
* feat: add dual-series chart rendering
* feat: integrate QuickJS for script execution
* feat: create persistent worker isolate
* feat: implement chart rendering with fl_chart
```

The merge approach **tells a story** of incremental progress.

---

### Emergency: Reverting a Milestone

If a milestone causes critical issues after merging to main:

```bash
# Find the merge commit
git log --oneline --merges

# Revert the entire milestone merge
git revert -m 1 <merge-commit-hash>

# Push
git push origin main

# Fix on dev, then re-merge when ready
```

---

### .gitignore Additions

Ensure these are in `.gitignore`:

```
# Flutter/Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.pub-cache/
.pub/
build/

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db

# Android
*.jks
*.keystore
local.properties

# Generated files
*.g.dart
*.freezed.dart

# Keep CLAUDE.md and milestone.md (project context)
# (these are NOT in .gitignore - we commit them)
```

---

### First Commit (Right Now)

Before starting Milestone 1:

```bash
# Ensure you're on main
git checkout main

# Add CLAUDE.md and milestone.md
git add .claude/CLAUDE.md milestone.md
git commit -m "docs: add project planning documentation

- CLAUDE.md: Complete project context, architecture, requirements
- milestone.md: 11-milestone development plan with git workflow

Planning Phase - Foundation Complete"

git push origin main

# Create and switch to dev branch
git checkout -b dev
git push -u origin dev

# Ready to start Milestone 1
```

---

### Summary

**Branch Model:** `main` ← `dev` (two branches only)

**Development:** All work on `dev`, commit frequently

**Merge to main:** After milestone 100% complete, use `git merge --no-ff dev`

**Why merge over rebase:** Preserves milestone boundaries, better for assessment review

**Commit messages:** Descriptive with type prefix, include milestone context

**First action:** Commit CLAUDE.md + milestone.md to main, create dev branch

---

## Timeline Overview

| Milestone | Duration | Cumulative | Status |
|-----------|----------|------------|--------|
| 1. Foundation | 1-2h | 2h | ⬜ Not Started |
| 2. UI Scaffolding | 2-3h | 5h | ⬜ Not Started |
| 3. BLE Scanning + Permissions | 4-5h | 10h | ⬜ Not Started |
| 4. BLE Connection + GATT Errors | 4-5h | 15h | ⬜ Not Started |
| 5. Data Parsing + Malformed Payloads | 3-4h | 19h | ⬜ Not Started |
| 6. Live Chart | 3-4h | 23h | ⬜ Not Started |
| 7. Worker Isolate + Scripting | 4-5h | 28h | ⬜ Not Started |
| 8. Camera + Permission Handling | 4-5h | 33h | ⬜ Not Started |
| 9. Persistence + Storage Checks | 3-4h | 37h | ⬜ Not Started |
| 10. Reconnection Logic | 3-4h | 41h | ⬜ Not Started |
| 11. Final Polish & Testing | 2-3h | 44h | ⬜ Not Started |

**Total Estimate:** ~44 hours (2 weeks part-time or 1 week full-time + buffer)

---

## MILESTONE 1: Project Foundation & Folder Structure

**Goal:** Set up architecture, models, folder structure, packages

**Duration:** 1-2 hours

**Status:** ⬜ Not Started

### Tasks

#### 1.1 Add Packages to `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter

  # BLE
  flutter_blue_plus: ^1.32.12

  # Charts
  fl_chart: ^0.69.0

  # Camera
  camera: ^0.11.0+2

  # Scripting
  flutter_js: ^0.8.1

  # Permissions
  permission_handler: ^11.3.1

  # Storage
  path_provider: ^2.1.4

  # State Management
  riverpod: ^2.6.1
  flutter_riverpod: ^2.6.1

  # Device Info
  device_info_plus: ^10.1.2

  # UI
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

**Command:** `flutter pub get`

---

#### 1.2 Create Folder Structure

```
lib/
├── main.dart
├── models/
│   ├── raw_sample.dart
│   ├── processed_sample.dart
│   ├── recording_session.dart
│   └── ble_connection_state.dart
├── services/
│   ├── ble_service.dart          # BLE comm layer
│   ├── worker_isolate.dart       # Data processing isolate
│   ├── camera_service.dart       # Camera recording
│   └── storage_service.dart      # JSON + video persistence
├── providers/
│   ├── ble_provider.dart
│   ├── chart_provider.dart
│   └── session_provider.dart
├── screens/
│   ├── scan_screen.dart          # Screen 1: Device list
│   └── main_screen.dart          # Screen 2: Recording
├── widgets/
│   ├── device_list_item.dart
│   ├── connection_status_bar.dart
│   ├── chart_placeholder.dart
│   └── hex_preview_widget.dart
└── utils/
    ├── constants.dart            # UUIDs, config
    ├── payload_parser.dart       # Byte parsing utilities
    └── logger.dart               # Debug logging
```

---

#### 1.3 Define Data Models

**`models/ble_connection_state.dart`:**
```dart
enum BLEConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  reconnecting,
  failed,
}
```

**`models/raw_sample.dart`:**
```dart
class RawSample {
  final int channel;      // uint16
  final int value;        // int16
  final DateTime timestamp;

  RawSample({
    required this.channel,
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'channel': channel,
    'value': value,
    'timestamp': timestamp.toIso8601String(),
  };
}
```

**`models/processed_sample.dart`:**
```dart
class ProcessedSample {
  final int channel;
  final int rawValue;
  final double processedValue;
  final DateTime timestamp;

  ProcessedSample({
    required this.channel,
    required this.rawValue,
    required this.processedValue,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'channel': channel,
    'rawValue': rawValue,
    'processedValue': processedValue,
    'timestamp': timestamp.toIso8601String(),
  };
}
```

**`models/recording_session.dart`:**
```dart
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
```

---

#### 1.4 Android Configuration

**`android/app/src/main/AndroidManifest.xml`:**

Add inside `<manifest>` tag (before `<application>`):

```xml
<!-- Android 12+ (API 31+) -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
                 android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Android 6-11 (API 23-30) -->
<uses-permission android:name="android.permission.BLUETOOTH"
                 android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"
                 android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"
                 android:maxSdkVersion="30" />

<!-- Camera -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Storage (Android 13+) -->
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />

<!-- Storage (Android 12 and below) -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
                 android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
                 android:maxSdkVersion="32" />
```

**`android/app/build.gradle`:**

```gradle
android {
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 28
    }
}
```

**Create `android/app/proguard-rules.pro`:**

```
-keep class com.lib.flutter_blue_plus.* { *; }
```

---

#### 1.5 Configure `main.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/scan_screen.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ScanScreen(),
    );
  }
}
```

---

#### 1.6 Create Constants

**`utils/constants.dart`:**

```dart
class BLEConstants {
  // Nordic UART Service (NUS)
  static const String nusServiceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const String nusTxCharUuid = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';

  // Device name
  static const String targetDeviceName = 'NUS-Py';

  // Scan config
  static const int scanTimeoutSeconds = 4;
  static const int maxScanAttempts = 5;

  // Connection config
  static const int maxConnectionAttempts = 5;
  static const List<int> reconnectBackoffSeconds = [1, 2, 4, 8, 16];

  // Chart config
  static const int maxChartPoints = 250;
  static const int chartRefreshMs = 16; // ~60fps

  // Storage
  static const int minStorageSpaceMB = 100;
}
```

---

### Deliverables

- ✅ `flutter pub get` runs successfully
- ✅ All folders created
- ✅ All 4 models defined with `toJson()` methods
- ✅ Android manifest configured
- ✅ Proguard rules created
- ✅ Constants file created
- ✅ App builds and launches (shows empty screen)

### Testing

```bash
flutter clean
flutter pub get
flutter run --debug
```

**Expected:** App launches on Android device without errors, shows blank screen.

---

## MILESTONE 2: Basic UI Scaffolding (Visual Feedback)

**Goal:** Two screens with navigation, placeholders for chart/camera

**Duration:** 2-3 hours

**Status:** ⬜ Not Started

### Tasks

#### 2.1 Create Scan Screen

**`screens/scan_screen.dart`:**

```dart
import 'package:flutter/material.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Device Scanner'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement scan logic
                // For now, navigate to main screen for testing
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                );
              },
              icon: const Icon(Icons.bluetooth_searching, size: 28),
              label: const Text('Scan for Devices'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Placeholder for device list
          const Expanded(
            child: Center(
              child: Text(
                'Discovered devices will appear here',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

#### 2.2 Create Main Screen

**`screens/main_screen.dart`:**

```dart
import 'package:flutter/material.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/hex_preview_widget.dart';
import '../widgets/chart_placeholder.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Live Monitor'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Status bar
          const ConnectionStatusBar(
            status: 'Disconnected',
            color: Colors.red,
          ),

          // Hex preview
          const HexPreviewWidget(
            hexString: '00 00 00 00 00 00 00 00',
          ),

          // Chart placeholder
          const Expanded(
            child: ChartPlaceholder(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement scan start/stop
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Scan'),
      ),
    );
  }
}
```

---

#### 2.3 Create Widgets

**`widgets/connection_status_bar.dart`:**

```dart
import 'package:flutter/material.dart';

class ConnectionStatusBar extends StatelessWidget {
  final String status;
  final Color color;

  const ConnectionStatusBar({
    super.key,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: color.withOpacity(0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, size: 12, color: color),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color.darken(0.3),
            ),
          ),
        ],
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darken(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }
}
```

**`widgets/hex_preview_widget.dart`:**

```dart
import 'package:flutter/material.dart';

class HexPreviewWidget extends StatelessWidget {
  final String hexString;

  const HexPreviewWidget({
    super.key,
    required this.hexString,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last Payload (hex)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hexString,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

**`widgets/chart_placeholder.dart`:**

```dart
import 'package:flutter/material.dart';

class ChartPlaceholder extends StatelessWidget {
  const ChartPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: Colors.blue.shade200,
            ),
            const SizedBox(height: 16),
            Text(
              'Live chart will appear here',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Deliverables

- ✅ Two screens created and navigable
- ✅ Status bar displays (red, "Disconnected")
- ✅ Hex preview widget displays placeholder
- ✅ Chart placeholder displays
- ✅ FAB displays with "Start Scan" text
- ✅ Proper Material Design aesthetics

### Testing

1. Run app on Android device
2. Tap "Scan for Devices" → Navigate to Main Screen
3. Verify all UI elements visible
4. Tap back button → Return to Scan Screen

**Expected:** UI renders correctly, navigation works smoothly.

---

## MILESTONE 3: BLE Scanning + Permission Handling

**Goal:** Scan for BLE devices, handle permissions, display devices in list

**Duration:** 4-5 hours

**Status:** ⬜ Not Started

### Tasks

#### 3.1 Permission Service

**`services/permission_service.dart`:**

```dart
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestBLEPermissions() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 31) {
      // Android 12+ (API 31+)
      final scanStatus = await Permission.bluetoothScan.request();
      final connectStatus = await Permission.bluetoothConnect.request();
      return scanStatus.isGranted && connectStatus.isGranted;
    } else {
      // Android 6-11 (API 23-30)
      final locationStatus = await Permission.locationWhenInUse.request();
      return locationStatus.isGranted;
    }
  }

  static Future<bool> checkBLEPermissions() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 31) {
      return await Permission.bluetoothScan.isGranted &&
             await Permission.bluetoothConnect.isGranted;
    } else {
      return await Permission.locationWhenInUse.isGranted;
    }
  }
}
```

---

#### 3.2 BLE Service (Initial)

**`services/ble_service.dart`:**

```dart
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/constants.dart';

class BLEService {
  final _scanResultsController = StreamController<List<ScanResult>>.broadcast();
  final List<ScanResult> _discoveredDevices = [];

  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  Future<void> startScan() async {
    if (_isScanning) return;

    _discoveredDevices.clear();
    _isScanning = true;

    // Start scan with timeout
    await FlutterBluePlus.startScan(
      timeout: Duration(seconds: BLEConstants.scanTimeoutSeconds),
    );

    // Listen to scan results
    FlutterBluePlus.scanResults.listen((results) {
      _discoveredDevices.clear();
      _discoveredDevices.addAll(results);
      _scanResultsController.add(List.from(_discoveredDevices));
    });

    // Stop after timeout
    await Future.delayed(Duration(seconds: BLEConstants.scanTimeoutSeconds));
    await stopScan();
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _isScanning = false;
  }

  void dispose() {
    _scanResultsController.close();
  }
}
```

---

#### 3.3 BLE Provider

**`providers/ble_provider.dart`:**

```dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ble_connection_state.dart';
import '../services/ble_service.dart';
import '../services/permission_service.dart';

class BLEState {
  final BLEConnectionState connectionState;
  final List<ScanResult> discoveredDevices;
  final bool isScanning;
  final String? errorMessage;

  BLEState({
    this.connectionState = BLEConnectionState.disconnected,
    this.discoveredDevices = const [],
    this.isScanning = false,
    this.errorMessage,
  });

  BLEState copyWith({
    BLEConnectionState? connectionState,
    List<ScanResult>? discoveredDevices,
    bool? isScanning,
    String? errorMessage,
  }) {
    return BLEState(
      connectionState: connectionState ?? this.connectionState,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      isScanning: isScanning ?? this.isScanning,
      errorMessage: errorMessage,
    );
  }
}

class BLENotifier extends StateNotifier<BLEState> {
  final BLEService _bleService = BLEService();

  BLENotifier() : super(BLEState()) {
    _bleService.scanResults.listen((results) {
      state = state.copyWith(discoveredDevices: results);
    });
  }

  Future<void> startScan() async {
    // Check permissions first
    final hasPermission = await PermissionService.checkBLEPermissions();
    if (!hasPermission) {
      final granted = await PermissionService.requestBLEPermissions();
      if (!granted) {
        state = state.copyWith(
          errorMessage: 'BLE permissions denied. Please enable in Settings.',
        );
        return;
      }
    }

    // Check if Bluetooth is on
    if (await FlutterBluePlus.isSupported == false) {
      state = state.copyWith(
        errorMessage: 'Bluetooth not supported on this device',
      );
      return;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      state = state.copyWith(
        errorMessage: 'Please enable Bluetooth',
      );
      return;
    }

    // Start scanning
    state = state.copyWith(
      isScanning: true,
      connectionState: BLEConnectionState.scanning,
      errorMessage: null,
    );

    await _bleService.startScan();

    state = state.copyWith(isScanning: false);
  }

  Future<void> stopScan() async {
    await _bleService.stopScan();
    state = state.copyWith(isScanning: false);
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }
}

final bleProvider = StateNotifierProvider<BLENotifier, BLEState>((ref) {
  return BLENotifier();
});
```

---

#### 3.4 Device List Item Widget

**`widgets/device_list_item.dart`:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceListItem extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onConnect;

  const DeviceListItem({
    super.key,
    required this.result,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final device = result.device;
    final deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : 'Unknown Device';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.bluetooth, color: Colors.blue),
        title: Text(
          deviceName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          device.remoteId.toString(),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: ElevatedButton(
          onPressed: onConnect,
          child: const Text('Connect'),
        ),
      ),
    );
  }
}
```

---

#### 3.5 Update Scan Screen

**Update `screens/scan_screen.dart`:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ble_provider.dart';
import '../widgets/device_list_item.dart';
import 'main_screen.dart';

class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Device Scanner'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),

          // Scan button
          ElevatedButton.icon(
            onPressed: bleState.isScanning
                ? null
                : () => ref.read(bleProvider.notifier).startScan(),
            icon: bleState.isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bluetooth_searching, size: 28),
            label: Text(bleState.isScanning ? 'Scanning...' : 'Scan for Devices'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),

          // Error message
          if (bleState.errorMessage != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                bleState.errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Device list
          Expanded(
            child: bleState.discoveredDevices.isEmpty
                ? const Center(
                    child: Text(
                      'No devices found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: bleState.discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final result = bleState.discoveredDevices[index];
                      return DeviceListItem(
                        result: result,
                        onConnect: () {
                          // TODO: Implement connection (Milestone 4)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MainScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
```

---

#### 3.6 Edge Case: Scan Rate Limiting (Android)

**Add to `services/ble_service.dart`:**

```dart
class BLEService {
  // ... existing code ...

  int _scanAttempts = 0;
  DateTime? _lastScanAttempt;

  Future<bool> canStartScan() async {
    final now = DateTime.now();

    // Reset counter if 30 seconds passed
    if (_lastScanAttempt != null &&
        now.difference(_lastScanAttempt!).inSeconds >= 30) {
      _scanAttempts = 0;
    }

    // Check if exceeded limit
    if (_scanAttempts >= BLEConstants.maxScanAttempts) {
      final timeSinceLastAttempt = now.difference(_lastScanAttempt!).inSeconds;
      if (timeSinceLastAttempt < 30) {
        // Still in cooldown
        return false;
      } else {
        // Cooldown expired, reset
        _scanAttempts = 0;
      }
    }

    return true;
  }

  Future<void> startScan() async {
    if (_isScanning) return;

    // Check rate limit
    if (!await canStartScan()) {
      throw Exception('Scan rate limit exceeded. Wait 30 seconds.');
    }

    _scanAttempts++;
    _lastScanAttempt = DateTime.now();

    // ... rest of startScan implementation ...
  }

  int getRemainingCooldownSeconds() {
    if (_lastScanAttempt == null || _scanAttempts < BLEConstants.maxScanAttempts) {
      return 0;
    }

    final elapsed = DateTime.now().difference(_lastScanAttempt!).inSeconds;
    final remaining = 30 - elapsed;
    return remaining > 0 ? remaining : 0;
  }
}
```

**Update BLEProvider to handle rate limiting:**

```dart
Future<void> startScan() async {
  // ... permission checks ...

  // Check rate limit
  try {
    state = state.copyWith(
      isScanning: true,
      connectionState: BLEConnectionState.scanning,
      errorMessage: null,
    );

    await _bleService.startScan();

    state = state.copyWith(isScanning: false);
  } catch (e) {
    final cooldown = _bleService.getRemainingCooldownSeconds();
    state = state.copyWith(
      isScanning: false,
      errorMessage: 'Too many scan attempts. Wait $cooldown seconds.',
    );
  }
}
```

---

### Deliverables

- ✅ Permission handling (SDK-branched: Android 6-11 vs 12+)
- ✅ BLE scan starts on button tap
- ✅ Discovered devices populate in ListView
- ✅ "Scanning..." UI feedback
- ✅ Permission denied error handling
- ✅ Bluetooth off error handling
- ✅ Scan rate limiting (max 5 scans per 30s)
- ✅ Cooldown timer displayed on rate limit

### Testing

1. **Permissions:**
   - Deny permissions → See error message
   - Grant permissions → Scan proceeds

2. **Bluetooth Off:**
   - Turn off Bluetooth → See "Enable Bluetooth" error
   - Turn on Bluetooth → Scan proceeds

3. **Scanning:**
   - Start BLE GATT server (NUS-Py)
   - Tap "Scan for Devices"
   - Verify NUS-Py appears in list
   - Tap "Connect" → Navigate to main screen

4. **Rate Limiting:**
   - Tap scan 5 times rapidly
   - 6th attempt should show cooldown error
   - Wait 30 seconds, try again → Should work

**Expected:** NUS-Py device visible in list, permissions handled gracefully, rate limiting enforced.

---

## MILESTONE 4: BLE Connection + GATT Error Handling

**Goal:** Connect to NUS-Py, subscribe to TX notifications, handle GATT errors

**Duration:** 4-5 hours

**Status:** ⬜ Not Started

### Tasks

#### 4.1 Add Connection Logic to BLE Service

**Update `services/ble_service.dart`:**

```dart
import 'package:flutter/services.dart';

class BLEService {
  // ... existing code ...

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _txCharacteristic;
  StreamSubscription<List<int>>? _notificationSubscription;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  final _notificationController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get notifications => _notificationController.stream;

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      // CRITICAL: Stop scanning before connecting
      await stopScan();

      // Connect to device
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;

      // Discover services
      final services = await device.discoverServices();

      // Find NUS service
      BluetoothService? nusService;
      try {
        nusService = services.firstWhere(
          (s) => s.uuid.toString().toUpperCase() ==
                 BLEConstants.nusServiceUuid.toUpperCase(),
        );
      } catch (e) {
        await device.disconnect();
        throw Exception('NUS service not found. Device not compatible.');
      }

      // Find TX characteristic
      try {
        _txCharacteristic = nusService.characteristics.firstWhere(
          (c) => c.uuid.toString().toUpperCase() ==
                 BLEConstants.nusTxCharUuid.toUpperCase(),
        );
      } catch (e) {
        await device.disconnect();
        throw Exception('TX characteristic not found.');
      }

      // Subscribe to notifications
      await _subscribeToNotifications(device);

      return true;
    } on PlatformException catch (e) {
      // GATT error handling
      if (e.code.contains('set_notification_failed')) {
        await device.disconnect();
        throw Exception('Device rejected subscription (GATT error ${e.code})');
      }
      rethrow;
    } catch (e) {
      await device.disconnect();
      rethrow;
    }
  }

  Future<void> _subscribeToNotifications(BluetoothDevice device) async {
    if (_txCharacteristic == null) return;

    // Set up listener
    _notificationSubscription = _txCharacteristic!.onValueReceived.listen(
      (bytes) {
        _notificationController.add(bytes);
      },
    );

    // Auto-cleanup on disconnect
    device.cancelWhenDisconnected(_notificationSubscription!, delayed: true);

    // Enable notifications
    await _txCharacteristic!.setNotifyValue(true);
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _txCharacteristic = null;
    }
  }

  void dispose() {
    _scanResultsController.close();
    _notificationController.close();
    _notificationSubscription?.cancel();
  }
}
```

---

#### 4.2 Update BLE Provider

**Update `providers/ble_provider.dart`:**

```dart
class BLEState {
  // ... existing fields ...
  final BluetoothDevice? connectedDevice;
  final List<int>? lastPayload;

  BLEState({
    this.connectionState = BLEConnectionState.disconnected,
    this.discoveredDevices = const [],
    this.isScanning = false,
    this.errorMessage,
    this.connectedDevice,
    this.lastPayload,
  });

  BLEState copyWith({
    BLEConnectionState? connectionState,
    List<ScanResult>? discoveredDevices,
    bool? isScanning,
    String? errorMessage,
    BluetoothDevice? connectedDevice,
    List<int>? lastPayload,
  }) {
    return BLEState(
      connectionState: connectionState ?? this.connectionState,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      isScanning: isScanning ?? this.isScanning,
      errorMessage: errorMessage,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      lastPayload: lastPayload ?? this.lastPayload,
    );
  }
}

class BLENotifier extends StateNotifier<BLEState> {
  // ... existing code ...

  BLENotifier() : super(BLEState()) {
    _bleService.scanResults.listen((results) {
      state = state.copyWith(discoveredDevices: results);
    });

    // Listen to notifications
    _bleService.notifications.listen((bytes) {
      state = state.copyWith(lastPayload: bytes);
    });
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    state = state.copyWith(
      connectionState: BLEConnectionState.connecting,
      errorMessage: null,
    );

    try {
      final success = await _bleService.connectToDevice(device);

      if (success) {
        state = state.copyWith(
          connectionState: BLEConnectionState.connected,
          connectedDevice: device,
        );
        return true;
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        connectionState: BLEConnectionState.failed,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> disconnect() async {
    await _bleService.disconnect();
    state = state.copyWith(
      connectionState: BLEConnectionState.disconnected,
      connectedDevice: null,
    );
  }
}
```

---

#### 4.3 Update Scan Screen with Connection Logic

**Update `screens/scan_screen.dart`:**

```dart
class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  Future<void> _handleConnect(
    BuildContext context,
    WidgetRef ref,
    BluetoothDevice device,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await ref.read(bleProvider.notifier).connectToDevice(device);

    // Dismiss loading
    if (context.mounted) Navigator.pop(context);

    if (success) {
      // Navigate to main screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } else {
      // Show error
      final errorMessage = ref.read(bleProvider).errorMessage;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Connection failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleProvider);

    return Scaffold(
      // ... existing AppBar ...
      body: Column(
        children: [
          // ... existing scan button ...

          Expanded(
            child: bleState.discoveredDevices.isEmpty
                ? const Center(child: Text('No devices found'))
                : ListView.builder(
                    itemCount: bleState.discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final result = bleState.discoveredDevices[index];
                      return DeviceListItem(
                        result: result,
                        onConnect: () => _handleConnect(
                          context,
                          ref,
                          result.device,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
```

---

#### 4.4 Update Main Screen Status Bar

**Update `screens/main_screen.dart`:**

```dart
class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  Color _getStatusColor(BLEConnectionState state) {
    switch (state) {
      case BLEConnectionState.connected:
        return Colors.green;
      case BLEConnectionState.reconnecting:
        return Colors.orange;
      case BLEConnectionState.connecting:
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  String _getStatusText(BLEConnectionState state) {
    switch (state) {
      case BLEConnectionState.connected:
        return 'Connected';
      case BLEConnectionState.reconnecting:
        return 'Reconnecting';
      case BLEConnectionState.connecting:
        return 'Connecting';
      case BLEConnectionState.scanning:
        return 'Scanning';
      case BLEConnectionState.failed:
        return 'Failed';
      default:
        return 'Disconnected';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleProvider);

    // Convert payload to hex string
    String hexString = '00 00 00 00 00 00 00 00';
    if (bleState.lastPayload != null && bleState.lastPayload!.isNotEmpty) {
      hexString = bleState.lastPayload!
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join(' ');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Live Monitor'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Status bar (real connection state)
          ConnectionStatusBar(
            status: _getStatusText(bleState.connectionState),
            color: _getStatusColor(bleState.connectionState),
          ),

          // Hex preview (real data)
          HexPreviewWidget(hexString: hexString),

          // Chart placeholder
          const Expanded(child: ChartPlaceholder()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement scan start/stop (Milestone 8)
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Scan'),
      ),
    );
  }
}
```

---

### Deliverables

- ✅ "Connect" button initiates connection
- ✅ Scan stops before connecting
- ✅ Service discovery finds NUS service
- ✅ TX characteristic subscription succeeds
- ✅ Navigate to main screen on success
- ✅ Status bar shows "Connected" (green)
- ✅ GATT errors handled with specific messages
- ✅ Service not found error handled
- ✅ Connection failures show snackbar

### Testing

1. **Successful Connection:**
   - Scan for NUS-Py
   - Tap "Connect"
   - Verify loading dialog appears
   - Main screen opens
   - Status bar shows "Connected" (green)

2. **GATT Errors:**
   - Try connecting to incompatible device
   - Verify error message displayed

3. **Service Discovery:**
   - Connect to NUS-Py
   - On main screen, press "Send sin(x)/x" on server
   - Verify hex preview updates with real bytes

**Expected:** Connection succeeds, status updates, hex preview shows incoming data.

---

## MILESTONE 5: Data Parsing + Malformed Payload Handling

**Goal:** Parse 8-byte payloads into RawSample objects, handle malformed data

**Duration:** 3-4 hours

**Status:** ⬜ Not Started

### Tasks

#### 5.1 Create Payload Parser

**`utils/payload_parser.dart`:**

```dart
import 'dart:typed_data';
import '../models/raw_sample.dart';

class PayloadParser {
  /// Parses 8-byte payload into 2 RawSample objects
  /// Format: [uint16 channel, int16 value] x 2 (big-endian)
  static List<RawSample> parse(List<int> bytes) {
    if (bytes.length != 8) {
      throw FormatException(
        'Invalid payload size: expected 8 bytes, got ${bytes.length}',
      );
    }

    final samples = <RawSample>[];
    final buffer = Uint8List.fromList(bytes).buffer;
    final data = ByteData.view(buffer);
    final timestamp = DateTime.now();

    try {
      // Parse first sample (bytes 0-3)
      final channel1 = data.getUint16(0, Endian.big);
      final value1 = data.getInt16(2, Endian.big);
      samples.add(RawSample(
        channel: channel1,
        value: value1,
        timestamp: timestamp,
      ));

      // Parse second sample (bytes 4-7)
      final channel2 = data.getUint16(4, Endian.big);
      final value2 = data.getInt16(6, Endian.big);
      samples.add(RawSample(
        channel: channel2,
        value: value2,
        timestamp: timestamp.add(const Duration(microseconds: 1)),
      ));

      return samples;
    } catch (e) {
      throw FormatException('Failed to parse payload: $e');
    }
  }

  /// Converts byte list to hex string for debugging
  static String toHexString(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }
}
```

---

#### 5.2 Create Chart Provider

**`providers/chart_provider.dart`:**

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/raw_sample.dart';
import '../utils/constants.dart';

class ChartState {
  final List<RawSample> rawSamples;
  final bool hasNewData;
  final int malformedCount;

  ChartState({
    this.rawSamples = const [],
    this.hasNewData = false,
    this.malformedCount = 0,
  });

  ChartState copyWith({
    List<RawSample>? rawSamples,
    bool? hasNewData,
    int? malformedCount,
  }) {
    return ChartState(
      rawSamples: rawSamples ?? this.rawSamples,
      hasNewData: hasNewData ?? this.hasNewData,
      malformedCount: malformedCount ?? this.malformedCount,
    );
  }
}

class ChartNotifier extends StateNotifier<ChartState> {
  ChartNotifier() : super(ChartState()) {
    _startThrottleTimer();
  }

  Timer? _throttleTimer;

  void _startThrottleTimer() {
    // 60fps throttle (~16ms)
    _throttleTimer = Timer.periodic(
      Duration(milliseconds: BLEConstants.chartRefreshMs),
      (_) {
        if (state.hasNewData) {
          // Reset flag (triggers UI rebuild)
          state = state.copyWith(hasNewData: false);
        }
      },
    );
  }

  void addSamples(List<RawSample> samples) {
    final updatedList = List<RawSample>.from(state.rawSamples)..addAll(samples);

    // Maintain rolling window (max 250 points)
    if (updatedList.length > BLEConstants.maxChartPoints) {
      final excess = updatedList.length - BLEConstants.maxChartPoints;
      updatedList.removeRange(0, excess);
    }

    state = state.copyWith(
      rawSamples: updatedList,
      hasNewData: true,
    );
  }

  void incrementMalformedCount() {
    state = state.copyWith(
      malformedCount: state.malformedCount + 1,
    );
  }

  void clearData() {
    state = ChartState();
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    super.dispose();
  }
}

final chartProvider = StateNotifierProvider<ChartNotifier, ChartState>((ref) {
  return ChartNotifier();
});
```

---

#### 5.3 Update BLE Provider to Parse Data

**Update `providers/ble_provider.dart`:**

```dart
import '../utils/payload_parser.dart';

class BLENotifier extends StateNotifier<BLEState> {
  final BLEService _bleService = BLEService();
  final Ref _ref;

  BLENotifier(this._ref) : super(BLEState()) {
    _bleService.scanResults.listen((results) {
      state = state.copyWith(discoveredDevices: results);
    });

    // Listen to notifications and parse
    _bleService.notifications.listen((bytes) {
      state = state.copyWith(lastPayload: bytes);
      _handleNotification(bytes);
    });
  }

  void _handleNotification(List<int> bytes) {
    try {
      // Parse payload
      final samples = PayloadParser.parse(bytes);

      // Add to chart provider
      _ref.read(chartProvider.notifier).addSamples(samples);

      // Log to console (debug)
      for (final sample in samples) {
        print('Parsed sample: channel=${sample.channel}, value=${sample.value}');
      }
    } on FormatException catch (e) {
      // Malformed payload
      print('Malformed payload: $e');
      print('Hex dump: ${PayloadParser.toHexString(bytes)}');

      // Increment malformed count
      _ref.read(chartProvider.notifier).incrementMalformedCount();
    }
  }

  // ... rest of existing code ...
}

// Update provider definition to pass ref
final bleProvider = StateNotifierProvider<BLENotifier, BLEState>((ref) {
  return BLENotifier(ref);
});
```

---

#### 5.4 Display Malformed Count (Debug UI)

**Update `widgets/hex_preview_widget.dart`:**

```dart
import 'package:flutter/material.dart';

class HexPreviewWidget extends StatelessWidget {
  final String hexString;
  final int? malformedCount;

  const HexPreviewWidget({
    super.key,
    required this.hexString,
    this.malformedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last Payload (hex)',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            hexString,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),

          // Show malformed count if > 0
          if (malformedCount != null && malformedCount! > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Malformed payloads: $malformedCount',
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ],
      ),
    );
  }
}
```

**Update `screens/main_screen.dart`:**

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final bleState = ref.watch(bleProvider);
  final chartState = ref.watch(chartProvider);

  // ... hex string conversion ...

  return Scaffold(
    // ... existing code ...
    body: Column(
      children: [
        ConnectionStatusBar(/*...*/),
        HexPreviewWidget(
          hexString: hexString,
          malformedCount: chartState.malformedCount,
        ),
        const Expanded(child: ChartPlaceholder()),
      ],
    ),
    // ... FAB ...
  );
}
```

---

### Deliverables

- ✅ Payload parser handles 8-byte big-endian format
- ✅ Parsed samples added to chart provider
- ✅ Malformed payloads logged with hex dump
- ✅ Malformed count tracked and displayed
- ✅ Console logs show parsed values
- ✅ Chart provider maintains rolling window (250 max)
- ✅ 60fps throttle implemented

### Testing

1. **Valid Payloads:**
   - Connect to NUS-Py
   - Send sin(x)/x data
   - Verify console logs: `Parsed sample: channel=1, value=100`
   - Verify hex preview updates

2. **Malformed Payloads:**
   - Manually send <8 bytes (simulate with test code)
   - Verify error logged with hex dump
   - Verify malformed count increments and displays

3. **Rolling Window:**
   - Let chart buffer exceed 250 samples
   - Verify oldest samples dropped

**Expected:** Parsing works, malformed data handled gracefully, no crashes.

---

## MILESTONE 6: Live Chart Integration

**Goal:** Display raw data on fl_chart in real-time

**Duration:** 3-4 hours

**Status:** ⬜ Not Started

### Tasks

#### 6.1 Create Live Chart Widget

**`widgets/live_chart_widget.dart`:**

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/raw_sample.dart';

class LiveChartWidget extends StatelessWidget {
  final List<RawSample> rawSamples;

  const LiveChartWidget({
    super.key,
    required this.rawSamples,
  });

  @override
  Widget build(BuildContext context) {
    if (rawSamples.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade200, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 64, color: Colors.blue.shade200),
              const SizedBox(height: 16),
              Text(
                'Waiting for data...',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 20,
            verticalInterval: 20,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            // Raw data series (blue)
            LineChartBarData(
              spots: _buildRawSpots(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          minY: _getMinY(),
          maxY: _getMaxY(),
        ),
      ),
    );
  }

  List<FlSpot> _buildRawSpots() {
    return List.generate(
      rawSamples.length,
      (index) => FlSpot(
        index.toDouble(),
        rawSamples[index].value.toDouble(),
      ),
    );
  }

  double _getMinY() {
    if (rawSamples.isEmpty) return -100;
    final values = rawSamples.map((s) => s.value).toList();
    return values.reduce((a, b) => a < b ? a : b).toDouble() - 10;
  }

  double _getMaxY() {
    if (rawSamples.isEmpty) return 100;
    final values = rawSamples.map((s) => s.value).toList();
    return values.reduce((a, b) => a > b ? a : b).toDouble() + 10;
  }
}
```

---

#### 6.2 Update Main Screen

**Update `screens/main_screen.dart`:**

```dart
import '../widgets/live_chart_widget.dart';

@override
Widget build(BuildContext context, WidgetRef ref) {
  final bleState = ref.watch(bleProvider);
  final chartState = ref.watch(chartProvider);

  // ... hex string conversion ...

  return Scaffold(
    appBar: AppBar(
      title: const Text('BLE Live Monitor'),
      centerTitle: true,
    ),
    body: Column(
      children: [
        ConnectionStatusBar(
          status: _getStatusText(bleState.connectionState),
          color: _getStatusColor(bleState.connectionState),
        ),
        HexPreviewWidget(
          hexString: hexString,
          malformedCount: chartState.malformedCount,
        ),

        // Live chart (replaces placeholder)
        Expanded(
          child: LiveChartWidget(
            rawSamples: chartState.rawSamples,
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        // TODO: Implement scan start/stop (Milestone 8)
      },
      icon: const Icon(Icons.play_arrow),
      label: const Text('Start Scan'),
    ),
  );
}
```

---

### Deliverables

- ✅ Chart displays with grid and axes
- ✅ Raw data plotted as blue line
- ✅ Chart updates in real-time (60fps throttle)
- ✅ Auto-scaling Y-axis based on data range
- ✅ Rolling window (last 250 points)
- ✅ "Waiting for data..." shown when empty
- ✅ No frame drops or lag

### Testing

1. **Chart Rendering:**
   - Connect to NUS-Py
   - Send sin(x)/x data
   - Verify chart displays sinc waveform
   - Verify smooth animation (no jank)

2. **Rolling Window:**
   - Let data stream for >250 samples
   - Verify chart scrolls (oldest data drops)

3. **Auto-scaling:**
   - Observe Y-axis adjusts to data range
   - Verify min/max values update

**Expected:** Live chart displays real-time sinc waveform smoothly!

---

## MILESTONE 7: Worker Isolate + Scripting Engine

**Goal:** Offload parsing to worker isolate, add scripting, show processed series

**Duration:** 4-5 hours (HARDEST MILESTONE)

**Status:** ⬜ Not Started

### Tasks

#### 7.1 Create Worker Isolate

**`services/worker_isolate.dart`:**

```dart
import 'dart:async';
import 'dart:isolate';
import 'package:flutter_js/flutter_js.dart';
import '../models/raw_sample.dart';
import '../models/processed_sample.dart';
import '../utils/payload_parser.dart';

class WorkerIsolate {
  Isolate? _isolate;
  SendPort? _sendPort;
  final _receivePort = ReceivePort();

  final _processedSamplesController = StreamController<List<ProcessedSample>>.broadcast();
  Stream<List<ProcessedSample>> get processedSamples => _processedSamplesController.stream;

  Future<void> start() async {
    _isolate = await Isolate.spawn(
      _isolateEntry,
      _receivePort.sendPort,
    );

    _receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
      } else if (message is List<ProcessedSample>) {
        _processedSamplesController.add(message);
      }
    });

    // Wait for isolate to be ready
    await Future.delayed(const Duration(milliseconds: 100));
  }

  void processPayload(List<int> bytes) {
    _sendPort?.send(bytes);
  }

  void stop() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _processedSamplesController.close();
  }

  static void _isolateEntry(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    // Initialize script engine
    final jsRuntime = getJavascriptRuntime();

    // Hardcoded script: processed = raw * 1.0
    const script = '''
      function transform(raw) {
        var processed = raw * 1.0;
        return processed;
      }
    ''';

    jsRuntime.evaluate(script);

    receivePort.listen((message) {
      if (message is List<int>) {
        try {
          // Parse bytes into RawSample objects
          final rawSamples = PayloadParser.parse(message);
          final processedSamples = <ProcessedSample>[];

          for (final raw in rawSamples) {
            // Execute script
            final result = jsRuntime.evaluate('transform(${raw.value})');
            final processedValue = result.numberValue;

            processedSamples.add(ProcessedSample(
              channel: raw.channel,
              rawValue: raw.value,
              processedValue: processedValue,
              timestamp: raw.timestamp,
            ));
          }

          // Send back to main isolate
          mainSendPort.send(processedSamples);
        } catch (e) {
          // Error handling - send empty list or log
          print('Worker isolate error: $e');
        }
      }
    });
  }
}
```

---

#### 7.2 Update Chart Provider for Processed Data

**Update `providers/chart_provider.dart`:**

```dart
import '../models/processed_sample.dart';

class ChartState {
  final List<RawSample> rawSamples;
  final List<ProcessedSample> processedSamples;
  final bool hasNewData;
  final int malformedCount;

  ChartState({
    this.rawSamples = const [],
    this.processedSamples = const [],
    this.hasNewData = false,
    this.malformedCount = 0,
  });

  ChartState copyWith({
    List<RawSample>? rawSamples,
    List<ProcessedSample>? processedSamples,
    bool? hasNewData,
    int? malformedCount,
  }) {
    return ChartState(
      rawSamples: rawSamples ?? this.rawSamples,
      processedSamples: processedSamples ?? this.processedSamples,
      hasNewData: hasNewData ?? this.hasNewData,
      malformedCount: malformedCount ?? this.malformedCount,
    );
  }
}

class ChartNotifier extends StateNotifier<ChartState> {
  // ... existing code ...

  void addProcessedSamples(List<ProcessedSample> samples) {
    final updatedRaw = List<RawSample>.from(state.rawSamples);
    final updatedProcessed = List<ProcessedSample>.from(state.processedSamples);

    // Add raw samples
    for (final sample in samples) {
      updatedRaw.add(RawSample(
        channel: sample.channel,
        value: sample.rawValue,
        timestamp: sample.timestamp,
      ));
    }

    // Add processed samples
    updatedProcessed.addAll(samples);

    // Maintain rolling window
    if (updatedRaw.length > BLEConstants.maxChartPoints) {
      final excess = updatedRaw.length - BLEConstants.maxChartPoints;
      updatedRaw.removeRange(0, excess);
      updatedProcessed.removeRange(0, excess);
    }

    state = state.copyWith(
      rawSamples: updatedRaw,
      processedSamples: updatedProcessed,
      hasNewData: true,
    );
  }
}
```

---

#### 7.3 Update BLE Service to Use Worker Isolate

**Update `services/ble_service.dart`:**

```dart
import 'worker_isolate.dart';

class BLEService {
  // ... existing code ...

  final WorkerIsolate _workerIsolate = WorkerIsolate();

  Stream<List<ProcessedSample>> get processedSamples => _workerIsolate.processedSamples;

  Future<void> initialize() async {
    await _workerIsolate.start();
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    // ... existing connection logic ...

    // In _subscribeToNotifications, forward to worker isolate
    _notificationSubscription = _txCharacteristic!.onValueReceived.listen(
      (bytes) {
        // Don't parse here - send to worker isolate
        _workerIsolate.processPayload(bytes);
      },
    );

    // ... rest of code ...
  }

  void dispose() {
    _workerIsolate.stop();
    // ... existing cleanup ...
  }
}
```

---

#### 7.4 Update BLE Provider

**Update `providers/ble_provider.dart`:**

```dart
class BLENotifier extends StateNotifier<BLEState> {
  final BLEService _bleService = BLEService();
  final Ref _ref;

  BLENotifier(this._ref) : super(BLEState()) {
    _initialize();

    // ... existing scan results listener ...

    // Listen to processed samples from worker isolate
    _bleService.processedSamples.listen((samples) {
      _ref.read(chartProvider.notifier).addProcessedSamples(samples);
    });
  }

  Future<void> _initialize() async {
    await _bleService.initialize();
  }

  // ... rest of code ...
}
```

---

#### 7.5 Update Chart Widget for Two Series

**Update `widgets/live_chart_widget.dart`:**

```dart
import '../models/processed_sample.dart';

class LiveChartWidget extends StatelessWidget {
  final List<RawSample> rawSamples;
  final List<ProcessedSample> processedSamples;

  const LiveChartWidget({
    super.key,
    required this.rawSamples,
    required this.processedSamples,
  });

  @override
  Widget build(BuildContext context) {
    // ... existing empty state ...

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Raw', Colors.blue),
              const SizedBox(width: 16),
              _buildLegendItem('Processed', Colors.orange),
            ],
          ),
          const SizedBox(height: 8),

          // Chart
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(/*...*/),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  // Raw series (blue)
                  LineChartBarData(
                    spots: _buildRawSpots(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),

                  // Processed series (orange)
                  LineChartBarData(
                    spots: _buildProcessedSpots(),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
                minY: _getMinY(),
                maxY: _getMaxY(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  List<FlSpot> _buildProcessedSpots() {
    return List.generate(
      processedSamples.length,
      (index) => FlSpot(
        index.toDouble(),
        processedSamples[index].processedValue,
      ),
    );
  }

  double _getMinY() {
    if (rawSamples.isEmpty) return -100;

    final rawValues = rawSamples.map((s) => s.value.toDouble());
    final processedValues = processedSamples.map((s) => s.processedValue);
    final allValues = [...rawValues, ...processedValues];

    return allValues.reduce((a, b) => a < b ? a : b) - 10;
  }

  double _getMaxY() {
    if (rawSamples.isEmpty) return 100;

    final rawValues = rawSamples.map((s) => s.value.toDouble());
    final processedValues = processedSamples.map((s) => s.processedValue);
    final allValues = [...rawValues, ...processedValues];

    return allValues.reduce((a, b) => a > b ? a : b) + 10;
  }
}
```

**Update `screens/main_screen.dart`:**

```dart
Expanded(
  child: LiveChartWidget(
    rawSamples: chartState.rawSamples,
    processedSamples: chartState.processedSamples,
  ),
),
```

---

### Deliverables

- ✅ Worker isolate spawned on app start
- ✅ Parsing moved to worker isolate (off main thread)
- ✅ QuickJS script engine initialized
- ✅ Hardcoded script executes: `processed = raw * 1.0`
- ✅ Processed samples sent back to main isolate
- ✅ Chart shows two series (blue raw, orange processed)
- ✅ Legend displays
- ✅ No UI blocking or frame drops

### Testing

1. **Worker Isolate:**
   - Connect and stream data
   - Verify console shows no parsing on main thread
   - Verify UI remains smooth (60fps)

2. **Dual Series:**
   - Verify chart shows two overlapping lines
   - Since script is `raw * 1.0`, lines should overlap exactly
   - Legend shows "Raw" (blue) and "Processed" (orange)

3. **Performance:**
   - Stream data for 1 minute
   - Verify no lag or stuttering
   - Check DevTools: main thread < 16ms per frame

**Expected:** Two-series chart working, processing off main thread, smooth performance!

---

## MILESTONE 8: Camera Integration + Permission Handling

**Goal:** Record video during scan, handle camera permissions

**Duration:** 4-5 hours

**Status:** ⬜ Not Started

### Tasks

#### 8.1 Create Camera Service

**`services/camera_service.dart`:**

```dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  CameraController? get controller => _controller;

  Future<bool> initialize() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      return false;
    }

    // Get available cameras
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      return false;
    }

    // Use back camera
    final camera = cameras.first;

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    return true;
  }

  Future<String?> startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    if (_isRecording) return null;

    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      return 'recording';
    } catch (e) {
      print('Error starting recording: $e');
      return null;
    }
  }

  Future<String?> stopRecording() async {
    if (_controller == null || !_isRecording) {
      return null;
    }

    try {
      final file = await _controller!.stopVideoRecording();
      _isRecording = false;

      // Move to app directory with timestamp
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final newPath = '${directory.path}/$timestamp.mp4';

      await File(file.path).copy(newPath);
      await File(file.path).delete();

      return newPath;
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  void dispose() {
    _controller?.dispose();
  }
}
```

---

#### 8.2 Create Session Provider

**`providers/session_provider.dart`:**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recording_session.dart';
import '../services/camera_service.dart';

class SessionState {
  final bool isRecording;
  final DateTime? recordingStartTime;
  final RecordingSession? lastSession;
  final String? errorMessage;

  SessionState({
    this.isRecording = false,
    this.recordingStartTime,
    this.lastSession,
    this.errorMessage,
  });

  SessionState copyWith({
    bool? isRecording,
    DateTime? recordingStartTime,
    RecordingSession? lastSession,
    String? errorMessage,
  }) {
    return SessionState(
      isRecording: isRecording ?? this.isRecording,
      recordingStartTime: recordingStartTime ?? this.recordingStartTime,
      lastSession: lastSession ?? this.lastSession,
      errorMessage: errorMessage,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  final CameraService _cameraService = CameraService();
  final Ref _ref;

  SessionNotifier(this._ref) : super(SessionState()) {
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final success = await _cameraService.initialize();
    if (!success) {
      state = state.copyWith(
        errorMessage: 'Camera permission denied or not available',
      );
    }
  }

  Future<void> startScan() async {
    if (state.isRecording) return;

    // Start camera recording
    final result = await _cameraService.startRecording();
    if (result == null) {
      state = state.copyWith(
        errorMessage: 'Failed to start camera recording',
      );
      return;
    }

    state = state.copyWith(
      isRecording: true,
      recordingStartTime: DateTime.now(),
      errorMessage: null,
    );
  }

  Future<void> stopScan() async {
    if (!state.isRecording) return;

    // Stop camera
    final videoPath = await _cameraService.stopRecording();

    if (videoPath != null) {
      // TODO: Save session with data (Milestone 9)
      print('Video saved: $videoPath');
    }

    state = state.copyWith(
      isRecording: false,
      recordingStartTime: null,
    );
  }

  CameraService get cameraService => _cameraService;

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref);
});
```

---

#### 8.3 Update Main Screen FAB

**Update `screens/main_screen.dart`:**

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final bleState = ref.watch(bleProvider);
  final chartState = ref.watch(chartProvider);
  final sessionState = ref.watch(sessionProvider);

  // ... existing code ...

  return Scaffold(
    // ... existing body ...
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () async {
        if (sessionState.isRecording) {
          // Stop scan
          await ref.read(sessionProvider.notifier).stopScan();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording stopped')),
          );
        } else {
          // Start scan
          await ref.read(sessionProvider.notifier).startScan();
        }
      },
      backgroundColor: sessionState.isRecording ? Colors.red : null,
      icon: Icon(
        sessionState.isRecording ? Icons.stop : Icons.play_arrow,
      ),
      label: Text(sessionState.isRecording ? 'Stop Scan' : 'Start Scan'),
    ),
  );
}
```

---

#### 8.4 Edge Case: Camera Permission Banner

**Create `widgets/permission_banner.dart`:**

```dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionBanner extends StatelessWidget {
  final String message;
  final Permission permission;

  const PermissionBanner({
    super.key,
    required this.message,
    required this.permission,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }
}
```

**Update `screens/main_screen.dart`:**

```dart
import '../widgets/permission_banner.dart';
import 'package:permission_handler/permission_handler.dart';

@override
Widget build(BuildContext context, WidgetRef ref) {
  // ... existing code ...

  return Scaffold(
    appBar: AppBar(/*...*/),
    body: Column(
      children: [
        ConnectionStatusBar(/*...*/),

        // Camera permission banner
        if (sessionState.errorMessage?.contains('Camera') == true)
          PermissionBanner(
            message: 'Camera disabled - grant permission to record video',
            permission: Permission.camera,
          ),

        HexPreviewWidget(/*...*/),
        Expanded(child: LiveChartWidget(/*...*/)),
      ],
    ),
    floatingActionButton: /*...*/,
  );
}
```

---

### Deliverables

- ✅ Camera initializes on app start
- ✅ Camera permission requested
- ✅ "Start Scan" FAB starts video recording
- ✅ "Stop Scan" FAB stops recording
- ✅ FAB changes color (blue → red) when recording
- ✅ FAB icon changes (play → stop)
- ✅ Video file saved with timestamp
- ✅ Permission denied shows banner (BLE continues working)
- ✅ File path logged to console

### Testing

1. **Permission Grant:**
   - First launch → Camera permission requested
   - Grant permission → Camera initializes
   - Tap "Start Scan" → Recording starts

2. **Permission Denied:**
   - Deny camera permission
   - Verify banner appears
   - Verify BLE + chart still work
   - Tap "Settings" → Opens app settings

3. **Recording:**
   - Start scan → FAB turns red, icon = stop
   - Record for 10 seconds
   - Stop scan → Snackbar "Recording stopped"
   - Check logs for video file path

**Expected:** Camera records independently, permission handling graceful!

---

## MILESTONE 9: Persistence + Storage Checks

**Goal:** Save JSON + video to device, check storage space

**Duration:** 3-4 hours

**Status:** ⬜ Not Started

### Tasks

#### 9.1 Create Storage Service

**`services/storage_service.dart`:**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/processed_sample.dart';
import '../models/recording_session.dart';
import '../utils/constants.dart';

class StorageService {
  Future<bool> hasEnoughSpace() async {
    final directory = await getApplicationDocumentsDirectory();
    final stat = await directory.statSync();
    final freeMB = stat.freeSpace ~/ (1024 * 1024);
    return freeMB >= BLEConstants.minStorageSpaceMB;
  }

  Future<RecordingSession> saveSession({
    required DateTime startTime,
    required DateTime endTime,
    required List<ProcessedSample> samples,
    required String videoPath,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');

    // Save JSON
    final jsonPath = '${directory.path}/$timestamp.json';
    final jsonData = {
      'session': {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'sampleCount': samples.length,
      },
      'samples': samples.map((s) => s.toJson()).toList(),
    };

    final jsonFile = File(jsonPath);
    await jsonFile.writeAsString(jsonEncode(jsonData));

    // Video already saved with timestamp in camera service
    // Just return session metadata
    final session = RecordingSession(
      startTime: startTime,
      endTime: endTime,
      rawDataFilePath: jsonPath,
      videoFilePath: videoPath,
      sampleCount: samples.length,
    );

    print('Session saved:');
    print('  JSON: $jsonPath');
    print('  Video: $videoPath');
    print('  Samples: ${samples.length}');

    return session;
  }
}
```

---

#### 9.2 Update Session Provider

**Update `providers/session_provider.dart`:**

```dart
import '../services/storage_service.dart';

class SessionNotifier extends StateNotifier<SessionState> {
  final CameraService _cameraService = CameraService();
  final StorageService _storageService = StorageService();
  final Ref _ref;

  // ... existing code ...

  Future<void> startScan() async {
    if (state.isRecording) return;

    // Check storage space
    final hasSpace = await _storageService.hasEnoughSpace();
    if (!hasSpace) {
      state = state.copyWith(
        errorMessage: 'Not enough storage space (need 100MB free)',
      );
      return;
    }

    // Start camera recording
    final result = await _cameraService.startRecording();
    if (result == null) {
      state = state.copyWith(
        errorMessage: 'Failed to start camera recording',
      );
      return;
    }

    state = state.copyWith(
      isRecording: true,
      recordingStartTime: DateTime.now(),
      errorMessage: null,
    );
  }

  Future<void> stopScan() async {
    if (!state.isRecording || state.recordingStartTime == null) return;

    // Stop camera
    final videoPath = await _cameraService.stopRecording();

    if (videoPath == null) {
      state = state.copyWith(
        isRecording: false,
        errorMessage: 'Failed to save video',
      );
      return;
    }

    // Get samples from chart provider
    final chartState = _ref.read(chartProvider);
    final samples = chartState.processedSamples;

    // Save session
    try {
      final session = await _storageService.saveSession(
        startTime: state.recordingStartTime!,
        endTime: DateTime.now(),
        samples: samples,
        videoPath: videoPath,
      );

      state = state.copyWith(
        isRecording: false,
        recordingStartTime: null,
        lastSession: session,
      );
    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        errorMessage: 'Failed to save session: $e',
      );
    }
  }

  // ... existing code ...
}
```

---

#### 9.3 Update Main Screen with Save Feedback

**Update `screens/main_screen.dart`:**

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ... existing code ...

  // Listen to session changes for save feedback
  ref.listen<SessionState>(sessionProvider, (previous, next) {
    if (previous?.isRecording == true && next.isRecording == false) {
      // Recording stopped
      if (next.lastSession != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Session saved (${next.lastSession!.sampleCount} samples)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  });

  return Scaffold(
    // ... existing code ...
  );
}
```

---

#### 9.4 Edge Case: Storage Full

**Update `screens/main_screen.dart` FAB:**

```dart
floatingActionButton: FloatingActionButton.extended(
  onPressed: sessionState.errorMessage?.contains('storage') == true
      ? null // Disable if storage full
      : () async {
          if (sessionState.isRecording) {
            await ref.read(sessionProvider.notifier).stopScan();
          } else {
            await ref.read(sessionProvider.notifier).startScan();
          }
        },
  backgroundColor: sessionState.isRecording ? Colors.red : null,
  icon: Icon(
    sessionState.isRecording ? Icons.stop : Icons.play_arrow,
  ),
  label: Text(sessionState.isRecording ? 'Stop Scan' : 'Start Scan'),
),
```

**Show storage error banner:**

```dart
// In Column children:
if (sessionState.errorMessage?.contains('storage') == true)
  PermissionBanner(
    message: sessionState.errorMessage!,
    permission: Permission.storage,
  ),
```

---

### Deliverables

- ✅ JSON file saved with session metadata + samples
- ✅ Video file saved with matching timestamp
- ✅ Storage space checked before recording
- ✅ Storage full error prevents scan start
- ✅ Success snackbar shows sample count
- ✅ Error snackbar on save failure
- ✅ Files logged to console

### Testing

1. **Successful Save:**
   - Connect to NUS-Py
   - Start scan, stream data for 30 seconds
   - Stop scan
   - Verify snackbar: "Session saved (X samples)"
   - Check device storage for JSON + MP4 files

2. **Storage Check:**
   - Fill device storage (or mock in code)
   - Try to start scan
   - Verify error: "Not enough storage space"
   - FAB disabled

3. **File Verification:**
   - Open JSON file, verify structure
   - Play video file, verify recording

**Expected:** Data persists correctly, storage checks prevent failures!

---

## MILESTONE 10: Reconnection Logic

**Goal:** Handle mid-session disconnects with auto-reconnect

**Duration:** 3-4 hours

**Status:** ⬜ Not Started

### Tasks

#### 10.1 Add Connection State Listener

**Update `services/ble_service.dart`:**

```dart
import 'dart:async';

class BLEService {
  // ... existing code ...

  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  final _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();

  Stream<BluetoothConnectionState> get connectionState => _connectionStateController.stream;

  Future<bool> connectToDevice(BluetoothDevice device) async {
    // ... existing connection code ...

    // Listen to connection state
    _connectionStateSubscription = device.connectionState.listen((state) {
      _connectionStateController.add(state);

      if (state == BluetoothConnectionState.disconnected) {
        _handleDisconnect(device);
      }
    });

    return true;
  }

  Future<void> _handleDisconnect(BluetoothDevice device) async {
    print('Disconnected from ${device.platformName}');
    // Provider will handle reconnection logic
  }

  Future<bool> reconnect(BluetoothDevice device) async {
    try {
      // Use autoConnect for faster reconnection
      await device.connect(autoConnect: true);

      // CRITICAL: Re-discover services after reconnect
      final services = await device.discoverServices();

      // Find NUS service again
      BluetoothService? nusService;
      try {
        nusService = services.firstWhere(
          (s) => s.uuid.toString().toUpperCase() ==
                 BLEConstants.nusServiceUuid.toUpperCase(),
        );
      } catch (e) {
        await device.disconnect();
        throw Exception('NUS service not found on reconnect');
      }

      // Find TX characteristic again
      try {
        _txCharacteristic = nusService.characteristics.firstWhere(
          (c) => c.uuid.toString().toUpperCase() ==
                 BLEConstants.nusTxCharUuid.toUpperCase(),
        );
      } catch (e) {
        await device.disconnect();
        throw Exception('TX characteristic not found on reconnect');
      }

      // Re-subscribe
      await _subscribeToNotifications(device);

      return true;
    } catch (e) {
      print('Reconnection failed: $e');
      return false;
    }
  }

  void dispose() {
    _connectionStateSubscription?.cancel();
    _connectionStateController.close();
    // ... existing cleanup ...
  }
}
```

---

#### 10.2 Update BLE Provider with Reconnection

**Update `providers/ble_provider.dart`:**

```dart
class BLENotifier extends StateNotifier<BLEState> {
  // ... existing code ...

  int _reconnectionAttempts = 0;

  BLENotifier(this._ref) : super(BLEState()) {
    _initialize();

    // ... existing listeners ...

    // Listen to connection state
    _bleService.connectionState.listen((connectionState) {
      if (connectionState == BluetoothConnectionState.disconnected &&
          state.connectedDevice != null) {
        _handleDisconnect();
      }
    });
  }

  Future<void> _handleDisconnect() async {
    if (state.connectionState == BLEConnectionState.reconnecting) {
      return; // Already reconnecting
    }

    state = state.copyWith(
      connectionState: BLEConnectionState.reconnecting,
    );

    _reconnectionAttempts = 0;
    await _attemptReconnect();
  }

  Future<void> _attemptReconnect() async {
    if (state.connectedDevice == null) return;

    final device = state.connectedDevice!;

    for (int attempt = 0; attempt < BLEConstants.maxConnectionAttempts; attempt++) {
      _reconnectionAttempts = attempt + 1;

      print('Reconnection attempt $_reconnectionAttempts/${BLEConstants.maxConnectionAttempts}');

      try {
        final success = await _bleService.reconnect(device);

        if (success) {
          // Reconnection successful
          state = state.copyWith(
            connectionState: BLEConnectionState.connected,
          );
          _reconnectionAttempts = 0;
          return;
        }
      } catch (e) {
        print('Reconnection attempt $_reconnectionAttempts failed: $e');
      }

      // Wait with exponential backoff
      if (attempt < BLEConstants.maxConnectionAttempts - 1) {
        final delay = BLEConstants.reconnectBackoffSeconds[attempt];
        await Future.delayed(Duration(seconds: delay));
      }
    }

    // All attempts failed
    state = state.copyWith(
      connectionState: BLEConnectionState.failed,
      errorMessage: 'Reconnection failed after $_reconnectionAttempts attempts',
    );
    _reconnectionAttempts = 0;
  }

  // ... existing code ...
}
```

---

#### 10.3 Update Connection Status Bar

**Update `screens/main_screen.dart`:**

```dart
String _getStatusText(BLEConnectionState state, BLENotifier notifier) {
  switch (state) {
    case BLEConnectionState.connected:
      return 'Connected';
    case BLEConnectionState.reconnecting:
      final attempt = notifier._reconnectionAttempts; // Make this accessible
      return 'Reconnecting ($attempt/5)';
    case BLEConnectionState.connecting:
      return 'Connecting';
    case BLEConnectionState.scanning:
      return 'Scanning';
    case BLEConnectionState.failed:
      return 'Connection Failed';
    default:
      return 'Disconnected';
  }
}
```

**Better approach - add attempt count to BLEState:**

```dart
// In providers/ble_provider.dart
class BLEState {
  // ... existing fields ...
  final int reconnectionAttempt;

  BLEState({
    // ... existing fields ...
    this.reconnectionAttempt = 0,
  });

  BLEState copyWith({
    // ... existing fields ...
    int? reconnectionAttempt,
  }) {
    return BLEState(
      // ... existing fields ...
      reconnectionAttempt: reconnectionAttempt ?? this.reconnectionAttempt,
    );
  }
}

// In _attemptReconnect:
state = state.copyWith(reconnectionAttempt: attempt + 1);
```

**Then in main_screen.dart:**

```dart
String _getStatusText(BLEState bleState) {
  switch (bleState.connectionState) {
    case BLEConnectionState.reconnecting:
      return 'Reconnecting (${bleState.reconnectionAttempt}/5)';
    // ... other cases ...
  }
}
```

---

### Deliverables

- ✅ Disconnect detected immediately
- ✅ Status bar shows "Reconnecting (N/5)"
- ✅ Auto-reconnect with exponential backoff
- ✅ Service re-discovery on reconnect
- ✅ Characteristic re-subscription on reconnect
- ✅ Chart freezes during disconnect
- ✅ Camera continues recording
- ✅ Data buffered in worker isolate
- ✅ Success: Resume data flow
- ✅ Failure: Show error after 5 attempts

### Testing

1. **Disconnect During Recording:**
   - Start recording
   - Stop BLE server (simulate disconnect)
   - Verify status → "Reconnecting (1/5)"
   - Restart server within 10 seconds
   - Verify reconnection succeeds
   - Verify chart resumes

2. **Failed Reconnection:**
   - Disconnect and don't restart server
   - Wait through all 5 attempts
   - Verify status → "Connection Failed"
   - Verify error message shown

3. **Data Preservation:**
   - Disconnect, wait 5 seconds, reconnect
   - Stop recording
   - Verify JSON includes data from before/after disconnect

**Expected:** Seamless reconnection, no data loss!

---

## MILESTONE 11: Final Polish & Testing

**Goal:** Code cleanup, comprehensive testing, README

**Duration:** 2-3 hours

**Status:** ⬜ Not Started

### Tasks

#### 11.1 Code Cleanup

- ✅ Remove debug print statements (or gate behind `kDebugMode`)
- ✅ Add inline comments for technical decisions
- ✅ Format code: `dart format .`
- ✅ Run linter: `flutter analyze`
- ✅ Fix any warnings/errors

#### 11.2 Comprehensive Testing

**Test Matrix:**

| Test Case | Expected Behavior |
|-----------|------------------|
| First launch | Permissions requested |
| BLE off | Error message |
| Permission denied | Clear error, Settings button |
| Scan for devices | NUS-Py appears |
| Connect to NUS-Py | Navigate to main screen, status "Connected" |
| Send sin(x)/x | Chart displays waveform |
| Dual series | Blue (raw) + Orange (processed) lines |
| Start scan | FAB red, camera records |
| Stream data | Hex preview updates, chart scrolls |
| Stop scan | Snackbar "Session saved", files created |
| Disconnect mid-scan | "Reconnecting" shown, chart freezes |
| Reconnect | Chart resumes, no data loss |
| Storage full | Error, FAB disabled |
| Scan rate limit | 30s cooldown enforced |

#### 11.3 Performance Verification

- ✅ Run DevTools profiler
- ✅ Verify main thread < 16ms per frame during streaming
- ✅ Verify no memory leaks (run for 5 minutes)
- ✅ Check app size (`flutter build apk --release`)

#### 11.4 Create README

**`README.md`:**

```markdown
# Masitek BLE App - Mobile Sensor Data Recorder

Flutter mobile application for connecting to BLE GATT servers, streaming real-time sensor data, and recording synchronized video.

## Features

- BLE device scanning and connection (Nordic UART Service)
- Real-time data parsing and visualization (dual-series line chart)
- Embedded JavaScript scripting engine for runtime data transformation
- Simultaneous video recording during data capture
- Persistent storage (JSON + MP4)
- Auto-reconnection with exponential backoff
- Android-focused (API 21+, tested on Android 9)

## Environment

- **Flutter:** 3.32.8
- **Dart:** 3.8.1
- **Target SDK:** Android 28
- **Min SDK:** Android 21
- **Test Device:** Infinix X652A (Android 9, API 28, 6GB RAM)

## BLE Server Setup

This app connects to a Nordic UART Service (NUS) BLE GATT server.

**Server Repository:**
```bash
cd /Users/dubemezeagwu/Developer/masitek-app/ble-gatt-server
git checkout bless-0.3.0-working
source .venv-0.3.0/bin/activate
python3 ble/main_headless.py
```

**Server Details:**
- Device Name: `NUS-Py`
- Service UUID: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
- TX Characteristic: `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`
- Payload: 8 bytes/notification (2 samples, big-endian)

## Running the App

```bash
flutter pub get
flutter run --debug
```

**Developer Options (Android):**
- Enable USB Debugging
- Enable "Stay Awake" during testing

## Architecture

**4-Layer Architecture:**

1. **BLE Communication Layer** - Scanning, connecting, subscribing (flutter_blue_plus)
2. **Worker Isolate** - CPU work (parsing, scripting, buffering) off main thread
3. **Presentation Layer** - State management (Riverpod), chart rendering (fl_chart)
4. **Camera Layer** - Independent video recording (camera package)

**Concurrency Strategy:**
- BLE notifications forwarded to worker isolate (main thread stays <16ms/frame)
- Chart throttled to 60fps
- Camera runs on OS thread

## Known Constraints

### BLE Server
- **Bless 0.3.0 advertising bug:** Android connection initially janky but stable once connected (library issue, not app)
- **Windows server recommended** for stable testing

### Android
- **Android 7/8:** OS-level BLE stack bugs (documented, not app-level)
- **Scan rate limiting:** Max 5 scans per 30 seconds (platform limit)

### flutter_blue_plus
- **Service re-discovery required** after every reconnect
- **Stop scan before connect** to avoid failures on some devices
- **Proguard rule required** for release builds

## Permissions

**Runtime Permissions (Android):**
- BLE (SDK-branched):
  - Android 12+: `BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT`
  - Android 6-11: `ACCESS_FINE_LOCATION`
- Camera: `CAMERA`
- Storage: `WRITE_EXTERNAL_STORAGE` (API <33) or `READ_MEDIA_VIDEO` (API 33+)

## Session Workflow

1. Scan for BLE devices
2. Connect to NUS-Py
3. Start Scan (camera records, data streams)
4. Press "Send sin(x)/x" on BLE server
5. Chart displays real-time waveform (raw + processed)
6. Stop Scan (saves JSON + video)

## File Persistence

**Location:** `getApplicationDocumentsDirectory()`

**Naming:** ISO 8601 timestamps (e.g., `2026-05-06T143022Z.json`)

**JSON Structure:**
```json
{
  "session": {
    "startTime": "2026-05-06T14:30:22Z",
    "endTime": "2026-05-06T14:32:45Z",
    "sampleCount": 1450
  },
  "samples": [
    {
      "channel": 1,
      "rawValue": 100,
      "processedValue": 100.0,
      "timestamp": "2026-05-06T14:30:22.145Z"
    }
  ]
}
```

## License

Private - Assessment Project
```

---

### Deliverables

- ✅ Code formatted and linted
- ✅ All test cases pass
- ✅ Performance verified (60fps, no leaks)
- ✅ README complete
- ✅ App ready for submission

### Final Checklist

- [ ] App builds without warnings
- [ ] All 7 requirements implemented
- [ ] Edge cases handled gracefully
- [ ] No crashes during 10-minute test
- [ ] Files persist correctly
- [ ] README accurate
- [ ] CLAUDE.md and milestone.md committed

---

## Development Notes

**Track Progress:**
- Update "Status" column as milestones complete
- Mark tasks with ✅ when done
- Add notes/issues encountered

**Refinement:**
- This plan will evolve as development progresses
- Add sub-tasks as needed
- Adjust time estimates based on actual progress

**Communication:**
- Raise blockers immediately
- Document technical decisions inline
- Update CLAUDE.md with new learnings

---

**Next Steps:** Start with Milestone 1 - Foundation & Folder Structure
