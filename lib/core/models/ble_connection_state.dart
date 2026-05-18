enum BleConnectionState {
  disconnected, // not connected to any device
  scanning, // actively scanning for devices
  connecting, // attempting to connect to a device
  connected, // successfully connected and subscribed to notifications
  reconnecting, // attempting to reconnect after mid-session disconnect
  failed, // connection or subscription failed after max retries
}