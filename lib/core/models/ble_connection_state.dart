/// Enum representing the full BLE connection lifecycle.
///
/// States:
/// - disconnected: Not connected to any device
/// - scanning: Actively scanning for devices
/// - connecting: Attempting to connect to a device
/// - connected: Successfully connected and subscribed to notifications
/// - reconnecting: Attempting to reconnect after mid-session disconnect
/// - failed: Connection or subscription failed after max retries
enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  reconnecting,
  failed,
}
