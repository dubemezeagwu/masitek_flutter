# Masitek Mobile App Developer - Coding Assessment

## PROJECT CRITICAL CONTEXT

**DEADLINE:** 90% complete in 2 weeks (May 6 → May 20, 2026)
**Interviewer:** Przemek Ostrowski (przemek@masitek.com)
**Assessment Focus:** **Architecture & technical design decisions** (NOT UI polish)
**Language:** Dart (Flutter)
**Project Type:** Coding assessment for Masitek Mobile App Developer position

### What Przemek Will Scrutinize
1. **Architectural clarity** - Code structure tells the story
2. **Concurrency correctness** - Highest scrutiny area
3. **Scripting layer quality** - Hardest requirement, highest differentiation
4. **Resilience** - Connection handling, permissions, error states
5. **Chart performance** - Functional and jank-free (visual design NOT assessed)

### Scope Management Rules
- **STAY FOCUSED:** 2-week timeline means NO overengineering
- **Architecture > Features:** If choosing between clean design and extra features, choose clean design
- **Functional > Perfect:** Working implementation beats perfect polish
- **Document decisions:** Inline comments explaining technical choices are valuable

---

## THE 7 CORE REQUIREMENTS

### 1. BLE Connection
Connect to Nordic UART Service (NUS) simulator, receive raw 8-byte payloads via notifications.

### 2. Concurrency
BLE I/O and data processing must NEVER block the UI thread. Use isolates for CPU work.

### 3. Live Charts
Plot raw sample values in real-time using `fl_chart` (2 series: raw + processed).

### 4. Video Recording
Capture video simultaneously while BLE data streams in.

### 5. Persistence
Save both raw data (JSON format) and video (MP4) to device storage.

### 6. Runtime Scripting
Embedded QuickJS engine executes transformations on incoming data.
**Initial implementation:** Hardcoded script (e.g., `processed = raw * 1.0`)

### 7. Processed Series
Show processed values alongside raw data on the same live chart.

---

## BLE GATT SERVER SETUP

### Server Location
**Path:** `/Users/dubemezeagwu/Developer/masitek-app/ble-gatt-server`
**Branch:** `bless-0.3.0-working` (ONLY this branch - DO NOT use `main` or `experimental`)

### Running the Server
```bash
cd /Users/dubemezeagwu/Developer/masitek-app/ble-gatt-server
git checkout bless-0.3.0-working
source .venv-0.3.0/bin/activate
python3 ble/main_headless.py
```

Once running, type `sinc` to send waveform data.

### BLE Protocol Details
- **Device Name:** `NUS-Py`
- **Service UUID:** `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
- **TX Characteristic UUID:** `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`
- **Payload Format:** 8 bytes per notification = 2 samples
  - Each sample: 4 bytes, **big-endian**
  - Bytes 0-1: `uint16` channel (fixed at 1)
  - Bytes 2-3: `int16` scaled sinc value
  - Example: `00 01 00 64` = channel 1, value 100

### Known Server Constraints
**CRITICAL:** Bless 0.3.0 on macOS has unstable BLE advertising with Android (GitHub issue #47)
- **Symptoms:** Initial connection often fails, advertising flickers in nRF Connect
- **Workaround:** Keep retrying - once connected, it's very stable (no disconnects)
- **Root cause:** Library bug in Bless 0.3.0 CoreBluetooth backend, NOT application bug
- **Note:** Windows server is stable - use for full-flow testing when available

This is a **known limitation** to document in README, not something to work around silently.

---

## SESSION MODEL & WORKFLOW

### BLE Connection
Long-lived connection that can persist across multiple recording sessions.

### "Scan" = Recording Session
A bounded period of simultaneous BLE streaming and video recording within a connection:

1. User taps **"Start Scan"** → Camera starts recording
2. User presses **"Send sin(x)/x"** on BLE GATT server
3. Data streams in → parsed → transformed → charted (raw + processed)
4. User taps **"Stop Scan"**
5. Video file saved + raw data persisted as JSON
6. Can initiate another scan without disconnecting BLE

### Component Independence (for debugging/testing)
BLE and Camera are **loosely coupled:**
- BLE can start without camera
- Camera can start without BLE
- Default behavior: auto-start camera when BLE connects (but not tightly coupled)

---

## HIGH-LEVEL ARCHITECTURE

### Four Distinct Layers with Strict Separation of Concerns

#### 1. BLE Communication Layer
- **Responsibility:** Scanning, connecting, subscribing to TX characteristic notifications
- **Implementation:** `flutter_blue_plus` package
- **Design principle:** Thin by design - receives bytes, immediately forwards to worker isolate
- **Thread:** Runs on main isolate (unavoidable with flutter_blue_plus)
- **State machine:** `BLEConnectionState` enum manages lifecycle

#### 2. Worker Isolate
- **Responsibility:** ALL CPU work (parsing, script execution, buffering, file serialization)
- **Lifecycle:** Spawned once at session start, kept alive for session duration, killed on session end
- **Communication:** Receives raw bytes via `SendPort`, sends processed samples back via its own `SendPort`
- **Thread:** Separate OS thread (true parallelism on multi-core devices)
- **Why persistent:** Spawning/killing isolates per notification is expensive on low-spec hardware

#### 3. Presentation Layer
- **Responsibility:** State management (Riverpod), chart data, UI rendering
- **State:** Receives only final processed values from worker isolate
- **Throttling:** Chart rebuilds throttled to ~60fps (decoupled from BLE notification rate)
- **Design principle:** NEVER does CPU work, only UI work

#### 4. Camera Layer
- **Responsibility:** Video recording
- **Implementation:** Official Flutter `camera` package
- **Thread:** Runs on its own OS-managed thread
- **Lifecycle:** Initialized before BLE starts, runs independently
- **Output:** Video file written directly by OS (no app-level file I/O)

#### 5. Session Controller (Orchestrator)
- **Responsibility:** Coordinates lifecycle of all 4 layers
- **Operations:** Start/stop BLE, start/stop camera, flush buffer on session end
- **Error handling:** Manages permission failures, connection errors, storage errors

---

## CONCURRENCY STRATEGY

### The Flow
1. **BLE notification arrives** (main isolate) → Thin callback receives bytes
2. **Forward to worker isolate** via `SendPort` (immediate return, no blocking)
3. **Worker isolate processes:**
   - Parse 8-byte payload into 2 `RawSample` objects
   - Execute script engine on each sample → `ProcessedSample`
   - Accumulate in buffer for persistence
   - Send processed samples back to main isolate
4. **Main isolate receives processed samples** → Throttle layer checks (60fps max)
5. **Chart rebuild** (only if new data arrived since last frame)

### Why This Approach
- BLE callback stays under 1ms (critical for not dropping notifications)
- All heavy work (parsing, script execution) isolated from UI thread
- Chart rendering never starves BLE I/O
- Camera runs independently, never competes for CPU

### Heavy One-Off Tasks
Use Flutter's `compute()` wrapper for:
- Session serialization (writing large JSON files)
- Any other CPU-intensive, non-recurring work

---

## DATA ENTITIES

### RawSample
Single decoded sensor reading from BLE payload.
```dart
class RawSample {
  final int channel;      // uint16, fixed at 1
  final int value;        // int16, scaled sinc value
  final DateTime timestamp;
}
```

### SampleChunk
One 8-byte BLE notification containing exactly 2 samples.
```dart
class SampleChunk {
  final RawSample sample1;
  final RawSample sample2;
}
```

### ProcessedSample
Output of scripting engine applied to a `RawSample`.
```dart
class ProcessedSample {
  final int channel;
  final int rawValue;
  final double processedValue;  // Output of script engine
  final DateTime timestamp;
}
```

### RecordingSession
Metadata for a bounded recording period.
```dart
class RecordingSession {
  final DateTime startTime;
  final DateTime endTime;
  final String rawDataFilePath;   // JSON file
  final String videoFilePath;     // MP4 file
  final int sampleCount;
}
```

### BLEConnectionState
Enum representing full connection lifecycle.
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

### ChartSeries
Rolling window of values for live chart (capped at 250 points).
```dart
class ChartSeries {
  final List<double> values;  // Max 250 points
  final List<DateTime> timestamps;

  // When buffer exceeds 250, drop oldest values
}
```

---

## FLUTTER PACKAGES

All packages pinned to **exact versions** in `pubspec.yaml`. `pubspec.lock` committed to repo.

| Package | Purpose | Notes |
|---------|---------|-------|
| `flutter_blue_plus` | BLE scanning, connecting, notifications | Explicit Android 9 support |
| `fl_chart` | Live line chart with 2 series | Native canvas rendering |
| `camera` | Video recording | Official Flutter team package |
| `flutter_js` | Embedded QuickJS JavaScript engine | Scripting layer, Android stable |
| `permission_handler` | BLE + camera permissions | SDK-branched (Android 6-12+) |
| `path_provider` | File system paths | Official Flutter package |
| `riverpod` | State management | Provider 2.x, null-safe |
| `device_info_plus` | Runtime Android SDK version detection | Drives permission branching |

---

## PERMISSIONS STRATEGY

### Android BLE - SDK-Branched at Runtime
- **Android 6-11 (API 23-30):** `ACCESS_FINE_LOCATION` required for BLE scanning (OS quirk)
- **Android 12+ (API 31+):** `BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT`
- Runtime SDK detection via `device_info_plus` determines which permissions to request

### Camera Permissions
- **All versions:** `CAMERA` permission (consistent)
- **Storage (Android 13+ vs older):**
  - Android 13+ (API 33): `READ_MEDIA_VIDEO`
  - Older: `WRITE_EXTERNAL_STORAGE`

### Permission Failure Handling
Each permission failure shows a **clear, specific error message**.
App degrades gracefully:
- BLE works without camera permission
- Camera works without BLE permission

---

## RETRY & RECONNECTION STRATEGY

### Scanning
- **Max attempts:** 5
- **Scan window:** 4 seconds per attempt
- **Delay between attempts:** 2 seconds
- **Failure:** Explicit error state after max attempts

### Connection
- **Max attempts:** 5
- **Backoff strategy:** Exponential (1s → 2s → 4s → 8s → 16s)
- **UI feedback:** Shows attempt count (e.g., "Connecting (3/5)")

### Mid-Session Disconnect

**Detection:** Immediate (via `device.connectionState.listen()`)

**Reconnection Flow:**
```dart
Connection lost detected
  ↓
1. Status bar → "Reconnecting" (yellow)
  ↓
2. Chart freezes (no new data)
  ↓
3. Camera CONTINUES recording
  ↓
4. Worker isolate CONTINUES buffering locally
  ↓
5. For each reconnection attempt (1-5):
   │
   ├─ await device.connect(autoConnect: true);  // Use autoConnect for known devices
   │
   ├─ CRITICAL: await device.discoverServices();  // MUST re-discover after EVERY reconnect
   │
   ├─ Find NUS service (6E400001-...)
   │   BluetoothService nusService = services.firstWhere(...);
   │
   ├─ Find TX characteristic (6E400003-...)
   │   BluetoothCharacteristic txChar = nusService.characteristics.firstWhere(...);
   │
   ├─ Re-subscribe (old subscription auto-cancelled by disconnect)
   │   final sub = txChar.onValueReceived.listen(...);
   │   device.cancelWhenDisconnected(sub, delayed: true);
   │
   ├─ await txChar.setNotifyValue(true);
   │
   └─ IF SUCCESS:
        - Status → "Connected" (green)
        - Resume data flow (worker isolate flushes buffer)
        - Chart resumes updating
        - BREAK (exit retry loop)

      IF FAILURE:
        - Wait (exponential backoff: 1s, 2s, 4s, 8s, 16s)
        - Retry (max 5 attempts)
  ↓
IF all attempts fail:
  - Status → "Disconnected" (red)
  - Show error snackbar
  - User can manually stop scan (saves partial data + video)
```

**Critical Rules:**
1. **ALWAYS re-discover services after reconnect** - Service handles are invalidated on disconnect
2. **ALWAYS re-subscribe to characteristics** - Old subscriptions are auto-cancelled
3. **Use `autoConnect: true`** - Returns immediately without timeout for known devices
4. **Worker isolate buffering** - Continues accumulating data during reconnect (no data loss)

**Data Preservation:**
- All raw samples preserved in worker isolate buffer
- Chart state frozen at last known values
- Camera continues recording throughout
- On reconnect success: buffer flushes to file, chart resumes

### UI Communication
Connection state is **always visible** (persistent status indicator, NOT a modal).
User sees: `Scanning` / `Connecting (N/5)` / `Connected` / `Reconnecting` / `Failed`

---

## EDGE CASES TO HANDLE

| Edge Case | Handling Strategy |
|-----------|-------------------|
| BLE disconnect mid-recording | Buffer locally, auto-reconnect (with service re-discovery), preserve all data |
| GATT subscription error (codes 1-17) | Device rejected `setNotifyValue(true)`. Disconnect, show "Device rejected subscription (GATT error X)", return to scan screen. Verify characteristic supports notify property. |
| Service discovery fails | Disconnect, show "Device not compatible (NUS service not found)", return to scan screen |
| Malformed payload (<8 bytes or unparseable) | Log error with hex dump, skip sample, continue processing. Track malformed count in debug UI. |
| Script runtime error | Processed series shows error state (red line or null), raw series continues uninterrupted. Log script error to console. |
| Camera permission denied | BLE and chart features continue independently. Show persistent banner: "Camera disabled - grant permission to record video" |
| BLE permission denied | Graceful error with clear user message and deep link to Settings. App cannot function without BLE. |
| Notification rate > chart render rate | Throttle layer absorbs burst (60fps cap), no frame drops. Worker isolate queues all data regardless. |
| Storage full | Detect before writing (check `Directory.statFs()`), surface error early. Prevent scan start if <100MB free. |
| Screen lock during session | iOS: Handled via background mode. Android: Document "Stay Awake" flag in Developer Options README. |
| Scan rate limiting (Android) | After 5 failed scan attempts, enforce 30s cooldown before allowing rescan. Show countdown timer in UI. |
| Duplicate notification listeners | Prevented via `device.cancelWhenDisconnected()` on every subscription. Old listeners auto-cancelled on disconnect. |

---

## SCRIPTING ENGINE DESIGN

### Engine Choice
**QuickJS** via `flutter_js` package (JavaScript runtime)

### Script Lifecycle
1. **Compilation:** Once on app start (or when script changes)
2. **Caching:** Compiled script stored in memory
3. **Execution:** Per incoming `RawSample` in worker isolate
4. **Error isolation:** Script errors affect processed series only (raw series unaffected)

### Initial Implementation
**Hardcoded script:**
```javascript
processed = raw * 1.0
```

Future enhancement: UI text field for user-defined transformations.

### Input/Output Format
- **Input variable:** `raw` (the int16 sample value)
- **Output:** `processed` (numeric result)
- **Example:** `processed = raw * 0.12 + 34`

### Execution Context
- **Thread:** Worker isolate (never main thread)
- **Performance:** Compilation is expensive (once), execution is cheap (per sample)

---

## PERSISTENCE FORMAT

### Raw Data: JSON
**File naming:** ISO 8601 timestamp (e.g., `2026-05-06T143022Z.json`)

**Structure:**
```json
{
  "session": {
    "startTime": "2026-05-06T14:30:22Z",
    "endTime": "2026-05-06T14:32:45Z",
    "sampleCount": 1450
  },
  "samples": [
    {
      "timestamp": "2026-05-06T14:30:22.145Z",
      "channel": 1,
      "rawValue": 100,
      "processedValue": 100.0
    }
  ]
}
```

**Why JSON:**
- Structured (supports nested metadata)
- Easy to read/debug
- Android handles natively
- Can include session metadata (start/end times, sample count)

### Video: MP4
**File naming:** ISO 8601 timestamp (e.g., `2026-05-06T143022Z.mp4`)
**Format:** Native camera output (handled by OS)

---

## TEST DEVICE SPECIFICATIONS

| Spec | Value |
|------|-------|
| **Device** | Infinix X652A (S5) |
| **Android** | 9 (API 28) |
| **Processor** | MediaTek Helio P22 - 8x Cortex-A53 @ 2.0GHz |
| **RAM** | 6GB |
| **Storage** | 128GB |
| **Screen** | 720x1600 |

### Hardware Characteristics
- **CPU:** Single efficiency-core cluster (parallelism real, but per-core performance modest)
- **Thermal:** Throttling possible under sustained load (isolate architecture prevents this)
- **Memory bandwidth:** Real bottleneck (minimize cross-isolate data size)
- **Camera + BLE simultaneously:** Viable (6GB RAM has comfortable headroom)

---

## ANDROID SDK CONFIGURATION

| Setting | Value | Reason |
|---------|-------|--------|
| `minSdkVersion` | 23 | Camera package requires API 23+ (Android 6.0) |
| `targetSdkVersion` | 28 | Test device, stable BLE stack |
| `ndkVersion` | 27.0.12077973 | Required by camera_android_camerax and other plugins |
| **Recommended minimum** | API 28 | Android 7/8 have OS-level BLE bugs (outside app control) |

**Note on minSdk=23:**
- Original plan was minSdk=21 (BLE introduced at API 21)
- Camera package (camera_android_camerax) requires API 23+
- **Impact:** App supports Android 6.0+ instead of Android 5.0+
- **Test device (API 28) unaffected** - Infinix X652A still compatible

**Note on Android 7/8:**
BLE instability on these versions is an **OS-level issue**, not application-level.
Document in README as known constraint, do NOT work around silently.

---

## PLATFORM-SPECIFIC SETUP

### iOS Configuration

#### Background BLE Support
**Required for:** Maintaining BLE connection when app goes to background (screen lock during recording)

**Add to `ios/Runner/Info.plist`:**
```xml
<key>UIBackgroundModes</key>
<array>
  <string>bluetooth-central</string>
</array>

<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect to sensor devices and receive data.</string>
```

**Add to `main.dart` (before any BLE operations):**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isIOS) {
    await FlutterBluePlus.setOptions(restoreState: true);
  }

  runApp(const MyApp());
}
```

**Why:** Without background mode, iOS suspends BLE when screen locks, causing disconnect during recording.

---

### Android Configuration

#### Proguard Rules (Release Builds)
**Required for:** Preventing crashes in release/production builds

**Add to `android/app/proguard-rules.pro`:**
```
-keep class com.lib.flutter_blue_plus.* { *; }
```

**Create file if it doesn't exist:**
```bash
touch android/app/proguard-rules.pro
```

**Why:** Without this rule, Proguard obfuscation breaks flutter_blue_plus in release builds.

#### Permissions (Already in Manifest)
Verify `android/app/src/main/AndroidManifest.xml` includes:

**Manifest declaration (add tools namespace):**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
          xmlns:tools="http://schemas.android.com/tools">
```

**Permissions:**
```xml
<!-- Android 12+ -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
                 android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Android 6-11 (Legacy) -->
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

<!-- Storage (Android 12 and below) - conflict resolver required -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
                 android:maxSdkVersion="32"
                 tools:replace="android:maxSdkVersion" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
                 android:maxSdkVersion="32" />
```

**Why `tools:replace`?** camera_android_camerax declares WRITE_EXTERNAL_STORAGE with maxSdkVersion=28, but we need 32. The `tools:replace` directive tells Gradle to use our value during manifest merger.

**Note:** Runtime permission handling via `permission_handler` package (SDK-branched logic in code).

---

### Debug Configuration

**Enable verbose BLE logging during development:**

**Add to `main.dart`:**
```dart
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Debug logging (only in debug builds)
  if (kDebugMode) {
    FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  }

  // iOS background support
  if (Platform.isIOS) {
    await FlutterBluePlus.setOptions(restoreState: true);
  }

  runApp(const MyApp());
}
```

**Log Output (color-coded):**
- ⚫ Function names
- 🟣 Platform arguments
- 🟡 Platform responses

**Custom log routing (optional):**
```dart
FlutterBluePlus.logs.listen((String logMessage) {
  // Route to custom logging service
  debugPrint('[FBP] $logMessage');
});
```

---

## CHART PERFORMANCE CONSTRAINTS

### Rolling Window
**Max data points:** 250 (prevents unbounded memory growth)
When buffer exceeds 250, drop oldest values.

### Chart Rebuild Throttling
**Max rate:** ~60fps (via periodic timer)
**Decoupling:** Chart rebuild rate is independent of BLE notification rate
**Optimization:** Chart only rebuilds when new data arrived (flag-checked before `setState`)

### Two Series on Same Chart
1. **Raw series:** Direct int16 values from BLE
2. **Processed series:** Output of script engine

---

## DEVELOPMENT ENVIRONMENT

| Component | Version |
|-----------|---------|
| **Flutter** | 3.32.8 (stable) |
| **Dart** | 3.8.1 |
| **Version Management** | No FVM (exact package pinning + committed `pubspec.lock`) |
| **Developer Options** | USB Debugging ON, Stay Awake enabled during testing |

---

## KNOWN CONSTRAINTS & NOTES

### BLE Server
- **Bless 0.3.0 advertising bug:** Android connection initially janky but stable once connected
- **Windows fallback:** Windows server recommended for stable Android testing
- **macOS version:** Development/testing only (not production-ready)

### Android OS
- **Android 7/8:** Have OS-level BLE stack bugs (not app-level issue)
- Document this in README as known constraint

### flutter_blue_plus Package
- **Bluetooth Classic NOT supported:** HC-05, HC-06, speakers, headphones, keyboards incompatible. Requires BLE GATT only.
- **Service re-discovery required:** MUST call `discoverServices()` after EVERY reconnect (handles invalidated on disconnect)
- **Subscription cleanup critical:** Always use `device.cancelWhenDisconnected()` to prevent memory leaks and duplicate listeners
- **Stop scan before connect:** Some Android devices fail simultaneous scan+connect operations
- **Scan rate limiting:** Max 5 scans per 30 seconds (Android platform limit) - enforce cooldown in app
- **GATT errors (codes 1-17):** Device rejection of read/write/notify requests - handle gracefully
- **iOS remoteId changes:** Periodically changes for privacy (Android uses static MAC)
- **Hot reload insufficient:** Full app restart required after adding plugin
- **Proguard required:** Must add keep rule for release builds or app will crash
- **autoConnect advantage:** Use `connect(autoConnect: true)` for known devices - returns immediately without timeout

### Assessment Scope
- **UI design:** Explicitly NOT assessed
- **Focus areas:** Architecture, concurrency, scripting, resilience

### Chart
- **Rolling window:** 250-point cap (prevent memory growth)
- **Visual design:** NOT assessed (functional > beautiful)

---

## README SECTIONS TO INCLUDE

When writing the project README, include:

1. **Environment** (Flutter version, Dart, target SDK, test device)
2. **BLE Server Setup** (branch, commands, device name)
3. **Known Constraints** (Bless advertising bug, Android 7/8 BLE note)
4. **Architecture Overview** (brief 4-layer description)
5. **Running the App** (flutter run commands, developer options)
6. **Permissions** (what's needed and why)
7. **Session Workflow** (how scans work within connection)

---

## UI/UX FLOW

### Two-Screen Application

#### Screen 1: BLE Device Scanner & Connection

**Initial State:**
- Single "Scan for Devices" button centered on screen

**Scanning State:**
- Button changes to "Scanning..." (disabled)
- ListView/Column appears showing discovered devices in real-time
- Each device item shows:
  - Device name (e.g., "NUS-Py")
  - Device ID/MAC address (optional, for debugging)
  - "Connect" button

**Connection Flow:**
```dart
User taps [Connect] on device
  ↓
1. await FlutterBluePlus.stopScan();  // CRITICAL: Stop scanning before connecting
  ↓
2. await device.connect();
  ↓
3. List<BluetoothService> services = await device.discoverServices();
  ↓
4. Find NUS service (6E400001-B5A3-F393-E0A9-E50E24DCCA9E)
   BluetoothService nusService = services.firstWhere(
     (s) => s.uuid == Guid("6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
   );
  ↓
5. Find TX characteristic (6E400003-B5A3-F393-E0A9-E50E24DCCA9E)
   BluetoothCharacteristic txChar = nusService.characteristics.firstWhere(
     (c) => c.uuid == Guid("6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
   );
  ↓
6. Set up notification listener + auto-cleanup
   final subscription = txChar.onValueReceived.listen((bytes) {
     // Forward to worker isolate for processing
   });
   device.cancelWhenDisconnected(subscription, delayed: true);
  ↓
7. Subscribe to notifications (with GATT error handling)
   try {
     await txChar.setNotifyValue(true);
   } on PlatformException catch (e) {
     if (e.code.contains('set_notification_failed')) {
       // GATT error: Device rejected subscription
       await device.disconnect();
       // Show specific error, return to scan list
     }
     rethrow;
   }
  ↓
8. Navigate to Main Screen (only after successful subscription confirmation)
```

**Critical Rules:**
1. ❌ **DON'T** navigate immediately after `device.connect()` succeeds
   ✅ **DO** navigate after `txCharacteristic.setNotifyValue(true)` confirms subscription

2. ❌ **DON'T** connect while scanning (causes failures on some Android devices)
   ✅ **DO** stop scan before connecting

3. ❌ **DON'T** forget subscription cleanup
   ✅ **DO** use `device.cancelWhenDisconnected()` to prevent memory leaks

**Why These Rules Matter:**
- **Subscription before navigation:** Connection can succeed but subscription can fail (GATT error). Navigating early lands user on main screen with no incoming data.
- **Stop scan before connect:** Some Android BLE stacks can't handle simultaneous scan+connect operations.
- **Auto-cleanup:** On disconnect/reconnect, old listeners can persist and cause duplicate data or memory leaks.

**Error Handling:**
- Connection fails: Show error snackbar, return to scan list
- Service discovery fails: Disconnect, show "Device not compatible (NUS service not found)"
- Subscription fails (GATT error): Disconnect, show "Device rejected subscription", return to scan list
- Permission denied: Show clear message with steps to enable in Settings

---

#### Screen 2: Main Recording Screen

**Layout (Top to Bottom):**

1. **Status Bar (Top)**
   - Connection state: "Connected" / "Reconnecting" / "Disconnected"
   - Color-coded: Green (connected), Yellow (reconnecting), Red (disconnected)

2. **Debug Info Row**
   - Label: "Last Payload (hex)"
   - Value: `00 01 fe ff 00 01 00 00` (updates with each notification)
   - Purpose: Debugging aid, shows raw bytes received

3. **Live Chart (Center - Main Area)**
   - **Two series on same chart:**
     - Blue line: Raw int16 values
     - Orange/Red line: Processed values (script output)
   - X-axis: Time (rolling window, last 250 points)
   - Y-axis: Value range (auto-scaling)
   - Chart updates in real-time as data streams in (throttled to 60fps)

4. **Camera Preview (Phase 2 - Nice to Have)**
   - Small rectangle overlay (e.g., 150x200 positioned bottom-left)
   - Shows live camera feed during recording
   - **Priority:** Low - implement after core features working
   - **Rationale:** Not in Przemek's reference screenshot, not a core requirement

5. **Floating Action Button (Bottom Right)**
   - **Idle state:** "Start Scan" icon/text
   - **Recording state:** "Stop Scan" icon/text (red background)

**Recording Workflow:**

```
User taps [Start Scan] FAB
  ↓
1. Camera starts recording (background, no preview in Phase 1)
  ↓
2. User presses "Send sin(x)/x" on BLE server
  ↓
3. BLE notifications arrive → Worker isolate processes
  ↓
4. Chart updates with raw + processed values (60fps throttle)
  ↓
User taps [Stop Scan] FAB
  ↓
5. Stop camera recording
  ↓
6. Serialize data to JSON (compute isolate)
  ↓
7. Save JSON + video files (ISO 8601 timestamps)
  ↓
8. Show "Saved" confirmation snackbar
```

**Disconnect Handling (Mid-Recording):**

```
BLE connection lost detected
  ↓
1. Status bar updates to "Reconnecting" (yellow)
  ↓
2. Chart freezes (no new data points)
  ↓
3. Camera CONTINUES recording (data preserved)
  ↓
4. Auto-reconnect attempts start (exponential backoff: 1s, 2s, 4s, 8s, 16s)
  ↓
IF reconnect succeeds:
  - Status → "Connected" (green)
  - Chart resumes updating
  - No data loss (worker isolate buffered during disconnect)
  ↓
IF reconnect fails after 5 attempts:
  - Status → "Disconnected" (red)
  - Show error snackbar
  - User can manually stop scan (saves partial data + video)
```

**State During Disconnect:**
- Worker isolate: Continues buffering (ready for reconnect)
- Camera: Keeps recording
- Chart: Frozen at last known values
- UI: Responsive, shows reconnection attempts

---

### Screen 3: History (Future - Phase 2)

**Scope:** Out of scope for 2-week deadline
**Implementation:** Add later if time permits

**Design Notes (for later):**
- List of past recording sessions
- Each item shows: Timestamp, duration, sample count, thumbnail
- Tap to view saved video + raw data
- Export options (share JSON, video)

**Prerequisite:** Build persistence layer correctly from day 1 (already planned).
Adding history screen becomes trivial if files use ISO 8601 naming + structured JSON.

---

### Development Phases

#### Phase 1: Core Functionality (2-Week Priority)
1. ✅ Screen 1: BLE scanning + connection + subscription
2. ✅ Screen 2: Status display + chart rendering
3. ✅ Worker isolate: Data parsing + script execution
4. ✅ Camera: Background recording (no preview)
5. ✅ Persistence: JSON + video saving
6. ✅ Reconnection: Auto-retry with exponential backoff

#### Phase 2: Polish (If Time Permits)
1. Camera preview overlay (small box on main screen)
2. History screen (list past sessions)
3. User-editable scripts (text input for transformations)
4. Chart visual polish (legends, grid lines, axis labels)

**Priority Rule:** Don't start Phase 2 until Phase 1 is 100% complete and tested.

---

### Key UI/UX Decisions

| Decision | Rationale |
|----------|-----------|
| Navigate after subscription (not connection) | Prevents landing on main screen with no data |
| No camera preview initially | Not in requirements, not in Przemek's screenshot |
| Status bar always visible | User always knows connection state (not hidden in modal) |
| Hex payload display | Debugging aid - shows raw data is arriving |
| FAB for scan control | Common Flutter pattern, doesn't obscure chart |
| Auto-reconnect (no user prompt) | Seamless experience, preserves data during brief disconnects |

---

## ANTI-PATTERNS TO AVOID

### Scope Creep
- ❌ Don't add features beyond the 7 requirements
- ❌ Don't polish UI (not assessed)
- ❌ Don't implement user-editable scripts initially (hardcode first)

### Overengineering
- ❌ Don't build complex state machines if simple enums suffice
- ❌ Don't create abstractions for single-use cases
- ❌ Don't optimize prematurely (profile first)

### Underengineering
- ❌ Don't block UI thread with heavy work
- ❌ Don't skip error handling for edge cases
- ❌ Don't ignore permission failures
- ❌ Don't leave technical decisions undocumented

---

## COMMUNICATION WITH CLAUDE

### When to Push Back
If Claude suggests features beyond the 7 requirements, remind:
> "That's out of scope for the 2-week deadline. Focus on the core requirements."

### When to Ask Questions
If architectural decisions have multiple valid approaches:
> "Should we use approach A (simpler, faster) or B (more flexible, slower)?"

### Technical Decisions to Document
Whenever making non-obvious choices, add inline comments explaining:
- Why this approach over alternatives
- What tradeoffs were considered
- How this aligns with assessment priorities

### Documentation Maintenance Protocol

**CRITICAL:** After every milestone completion or significant change, **IMMEDIATELY** update all relevant documentation to prevent stale information.

**Documentation files to keep synchronized:**
1. **CLAUDE.md** - Architecture decisions, configuration values, constraints
2. **milestone.md** - Task completion status, updated file paths, refined estimates
3. **Inline code comments** - Technical decisions, why specific approaches were chosen

**When to update:**
- ✅ After completing a milestone (before merging to main)
- ✅ After fixing build errors (SDK versions, NDK, manifest changes)
- ✅ After architectural refactors (folder structure, package changes)
- ✅ When discovering new constraints (library limitations, platform bugs)
- ✅ When changing SDK/API requirements (minSdk, targetSdk, permissions)

**Example scenarios:**
- **Milestone 1 completion:** Updated minSdk (21→23), NDK version, folder structure paths
- **Build fix:** Documented `tools:replace` manifest conflict resolver
- **Package analysis:** Added flutter_blue_plus constraints to CLAUDE.md

**Why this matters:**
- Prevents confusion when resuming work after breaks
- Ensures Przemek sees accurate, up-to-date documentation during code review
- Maintains single source of truth for architectural decisions
- Helps future debugging by documenting "why" decisions were made

**Action for Claude:**
- At the end of EVERY milestone, proactively ask: "Should I update CLAUDE.md and milestone.md to reflect the changes we just made?"
- When making configuration changes (build.gradle, manifest, etc.), immediately update relevant documentation sections
- Keep milestone.md status column current (⬜ → 🔄 → ✅)

---

**Last Updated:** 2026-05-08
**Project Status:** Milestone 1 complete - Foundation & folder structure refactored to layered architecture
