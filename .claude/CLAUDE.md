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
- **Detection:** Immediate (connection state listener)
- **UI update:** Changes to `Reconnecting` state
- **Data handling:** Buffer continues accumulating locally (no data loss)
- **Reconnection:** Automatic retry with same backoff strategy
- **Data preservation:** All raw samples preserved throughout disconnect/reconnect

### UI Communication
Connection state is **always visible** (persistent status indicator, NOT a modal).
User sees: `Scanning` / `Connecting (N/5)` / `Connected` / `Reconnecting` / `Failed`

---

## EDGE CASES TO HANDLE

| Edge Case | Handling Strategy |
|-----------|-------------------|
| BLE disconnect mid-recording | Buffer locally, auto-reconnect, preserve all data |
| Malformed payload (<8 bytes or unparseable) | Log error, skip sample, continue processing |
| Script runtime error | Processed series shows error state, raw series continues uninterrupted |
| Camera permission denied | BLE and chart features continue independently |
| BLE permission denied | Graceful error with clear user message |
| Notification rate > chart render rate | Throttle layer absorbs burst, no frame drops |
| Storage full | Detect before writing, surface error early |
| Screen lock during session | Document "Stay Awake" flag in README (developer options) |

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
| `minSdkVersion` | 21 | BLE introduced at API 21 |
| `targetSdkVersion` | 28 | Test device, stable BLE stack |
| **Recommended minimum** | API 28 | Android 7/8 have OS-level BLE bugs (outside app control) |

**Note on Android 7/8:**
BLE instability on these versions is an **OS-level issue**, not application-level.
Document in README as known constraint, do NOT work around silently.

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

---

**Last Updated:** 2026-05-06
**Project Status:** Initial setup - CLAUDE.md created
