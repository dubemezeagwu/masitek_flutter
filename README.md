# Masitek BLE Data Recorder

Mobile app for recording real-time BLE sensor data with synchronized video capture and live charting built primarily for Android with Flutter.

---

## Core Features

1. **BLE Connection** - Connect to Nordic UART Service (NUS) devices
2. **Real-time Charting** - Live visualization of raw and processed sensor values
3. **Video Recording** - Synchronized video capture during data sessions
4. **Data Persistence** - Export raw data (JSON) and video (MP4) to device storage
5. **Worker Isolate** - CPU-intensive processing isolated from UI thread
6. **Runtime Scripting** - Embedded QuickJS engine for data transformations
7. **Reconnection Handling** - Automatic reconnection with exponential backoff

---

## Environment

| Component | Version |
|-----------|---------|
| **Flutter** | 3.32.8 |
| **Dart** | 3.8.1 |
| **minSdkVersion** | 23 (Android 6.0+) |
| **targetSdkVersion** | 28 |
| **Test Device** | Infinix X652A (Android 9, 6GB RAM) |

---

## Installation

### Prerequisites

- Flutter SDK 3.32.8+ ([install guide](https://docs.flutter.dev/get-started/install))
- Android SDK API 28+
- Physical Android device (API 23+) with BLE support
- USB debugging enabled on device
- **Bluetooth required, WiFi/Internet NOT required** (app works offline)

**Note:** BLE testing on emulators is unreliable. Use physical device.

### Setup

1. **Clone repository**
   ```bash
   git clone <repository-url>
   cd masitek_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Connect device and verify**
   ```bash
   flutter devices  # Your device should appear
   flutter doctor   # Ensure no errors
   ```

4. **Run app**
   ```bash
   flutter run --debug
   ```
---

## Test BLE Protocol Details
- **Device Name:** `NUS-Py`
- **Service UUID:** `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
- **TX Characteristic UUID:** `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`
- **Payload Format:** 8 bytes per notification = 2 samples (big-endian)
  - Bytes 0-1: `uint16` channel (fixed at 1)
  - Bytes 2-3: `int16` scaled sinc value

### Known Server Constraint
**macOS BLE advertising issue (Bless 0.3.0):** Initial connection may require multiple attempts due to library bug. Once connected, the session is stable with no disconnects. This is a known Bless library limitation, not an application issue.

---

## Architecture

### Four-Layer Design

```
┌─────────────────────────────────────────────────────────┐
│                   Presentation Layer                     │
│  (Riverpod providers, UI widgets, chart rendering)      │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                      BLE Layer                           │
│        (flutter_blue_plus - scanning, connection)        │
└──────────────────────┬──────────────────────────────────┘
                       │ Raw bytes
┌──────────────────────▼──────────────────────────────────┐
│                   Worker Isolate                         │
│  (Parsing, script execution, buffering, serialization)   │
└──────────────────────┬──────────────────────────────────┘
                       │ Processed samples
┌──────────────────────▼──────────────────────────────────┐
│                   Camera Layer                           │
│          (Independent video recording thread)            │
└─────────────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **BLE → Worker Isolate Pipeline**
   BLE notifications forwarded immediately to isolate via `SendPort` (< 1ms callback time). All CPU work (parsing, scripting, buffering) happens off-thread.

2. **Rolling Window Chart**
   Chart data capped at 1000 points. Oldest values dropped when buffer exceeds limit (prevents unbounded memory growth).

3. **Camera Independence**
   Camera runs on OS-managed thread. Recording continues during BLE reconnection events.

4. **Reconnection Strategy**
   Exponential backoff (1s → 2s → 4s → 8s → 16s). Service re-discovery + re-subscription required after every reconnect. Worker isolate buffers data locally during reconnection.

5. **Scripting Engine**
   QuickJS embedded for runtime transformations. Initial implementation: hardcoded `processed = raw * 1.0` with Dart. Script errors affect processed series only (raw series continues).

6. **App Lifecycle Management**
   `WidgetsBindingObserver` handles Android lifecycle events. When app backgrounds (onPause): camera released + RSSI polling paused **unless actively recording**. When recording: resources kept alive to preserve session. When app foregrounds (onResume): camera reinitialized + RSSI polling resumed (if not already active). BLE connection stays alive via auto-reconnect logic.

   **Trade-off:** Background recording continues but is not guaranteed (no foreground service). System may interrupt camera on some devices. For production, implement Android Foreground Service with persistent notification.

---

## Permissions

### Android BLE (SDK-Branched)
- **Android 6-11 (API 23-30):** `ACCESS_FINE_LOCATION` (OS quirk for BLE scanning)
- **Android 12+ (API 31+):** `BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT`

Runtime SDK detection via `device_info_plus` determines which permissions to request.

### Camera & Storage
- **All versions:** `CAMERA` permission
- **Android 13+ (API 33):** `READ_MEDIA_VIDEO`
- **Android 12 and below:** `WRITE_EXTERNAL_STORAGE` (maxSdkVersion: 32)

Permissions requested upfront at app launch to avoid workflow interruptions.

---

## Performance Results

### Test Conditions
- **Build Mode:** Profile
- **Device:** Infinix X652A (Android 9, MediaTek Helio P22, 6GB RAM)
- **BLE Server:** macOS (bless-0.3.0-working branch)
- **Session Duration:** 30 seconds active streaming

### Runtime Metrics (In-App Overlay)

| Metric | Observed Value | Analysis |
|--------|----------------|----------|
| **FPS** | 5-13 fps | Reflects data arrival rate (efficient frame skipping) |
| **BLE Notification Rate** | 9-10/s | ~18-20 samples/s (2 samples per notification) |
| **Chart Render Rate** | 9-10/s | 1:1 with BLE rate (optimal throughput) |
| **UI Responsiveness** | Smooth | No jank, touch events responsive |

### Memory Profiling (Flutter DevTools)

| Class | Instances | Memory | Notes |
|-------|-----------|--------|-------|
| **ChartDataPoint** | 512 | 24.5 KB | Rolling window working (cap: 1000) |
| **ProcessedSample** | 518 | 24.8 KB | Worker isolate buffer |
| **FlSpot (fl_chart)** | 10,897 | 348 KB | Chart rendering (bounded) |
| **Total App Data** | — | ~50 KB | Core architecture overhead |

### Architecture Validation

**No memory leaks detected** - All singletons show 1 instance
**Rolling window enforced** - Chart data capped at 512/1000 points
**Worker isolate efficient** - Single isolate, reused throughout session
**BLE throughput** - 9-10 notifications/s with zero frame drops
**Camera independence** - Recording continues during BLE reconnect

---

## Testing Summary

### Test Scenarios Completed

| Scenario | Result | Notes |
|----------|--------|-------|
| **BLE Scan → Connect → Subscribe** | Pass | NUS service discovery + TX characteristic subscription |
| **Data Reception → Parsing → Chart** | Pass | 8-byte payloads decoded to 2 samples, displayed on chart |
| **Video Recording + BLE Streaming** | Pass | Simultaneous camera recording and data ingestion |
| **Worker Isolate Buffering** | Pass | JSON sample count matches transmitted data |
| **Mid-Session Disconnect** | Pass | Auto-reconnect with exponential backoff, no data loss |
| **Navigation Flow** | Pass | Scan → Connect → Session → Back → Disconnect |
| **Permission Denials** | Pass | Graceful degradation (BLE works without camera, etc.) |
| **File Persistence** | Pass | Video (MP4) + raw data (JSON) saved to device storage |

### File Output Locations

- **Videos:** `/storage/emulated/0/Android/data/com.example.masitek_flutter/files/Videos/`
- **Session Data:** `/storage/emulated/0/Android/data/com.example.masitek_flutter/files/Sessions/`

Filename format: `masitek_DD_MM_YYYY_HH_MM.{mp4,json}`

---

## Known Constraints

1. **Bless 0.3.0 Advertising Bug (macOS)**
   Initial BLE connection often requires multiple retry attempts. This is a library issue in the GATT server, not the mobile app. Once connected, sessions are stable.

2. **Android 7/8 BLE Stack Issues**
   Android 7 and 8 have OS-level BLE bugs outside application control. App targets API 28 (Android 9) minimum for stable BLE operations.

3. **Memory Tracking Limitation**
   In-app performance overlay shows `Memory: 0.0 MB` (placeholder). Use Flutter DevTools for accurate memory profiling.

4. **Screen Lock (Android)**
   To prevent disconnection during recording, enable "Stay Awake" in Developer Options on Android.

5. **Background Recording**
   Camera and RSSI polling stay alive during active recording sessions when app backgrounds. However, system may still interrupt recording on some devices (no foreground service implemented). For guaranteed background recording, implement Android Foreground Service.

---

## Project Structure

```
lib/
├── core/
│   ├── models/            # Domain models (BleState, ChartDataPoint, etc.)
│   ├── constants/         # App constants
│   ├── extensions/        # Dart extensions
│   └── theme/             # Material theme
├── data/
│   ├── isolate/           # Worker isolate (parsing, scripting, buffering)
│   ├── buffer/            # Sample buffer for persistence
│   ├── parser/            # BLE payload parser
│   └── scripting/         # QuickJS script engine
├── ble/
│   ├── ble_scanner.dart         # BLE device scanning
│   ├── ble_connection_manager.dart  # Connection lifecycle
│   └── ble_permission_handler.dart  # Runtime permissions
├── presentation/
│   ├── providers/         # Riverpod state management
│   ├── screens/           # UI screens (ScanScreen, MainScreen)
│   └── widgets/           # Reusable widgets
└── services/
    ├── camera_service.dart      # Video recording
    └── persistence_service.dart # File serialization
```

---

## Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_blue_plus` | ^1.33.10 | BLE scanning, connection, notifications |
| `fl_chart` | ^0.69.2 | Real-time line chart rendering |
| `camera` | ^0.11.0+3 | Video recording |
| `flutter_js` | ^0.8.1 | Embedded QuickJS scripting engine |
| `permission_handler` | ^11.3.1 | Runtime permission requests (SDK-branched) |
| `riverpod` | ^2.6.1 | State management |
| `device_info_plus` | ^11.2.0 | Android SDK version detection |
| `path_provider` | ^2.1.5 | File system paths |

All packages pinned to exact versions. `pubspec.lock` committed for reproducibility.

---

## Development Notes

### Proguard Configuration (Release Builds)

Add to `android/app/proguard-rules.pro`:
```
-keep class com.lib.flutter_blue_plus.* { *; }
-keep class io.flutter.plugins.camera.** { *; }
-keep class androidx.camera.** { *; }
```

### iOS Background BLE (Future Enhancement)

Add to `ios/Runner/Info.plist` if iOS support needed:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>bluetooth-central</string>
</array>
```

---

## Future Enhancements (Out of Scope)

- User-editable script transformations (text input for QuickJS code)
- Session history screen (list past recordings)
- Export to cloud storage
- Multi-device simultaneous connection