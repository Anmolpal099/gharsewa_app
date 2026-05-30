/// Represents the current state of the WebSocket connection
enum ConnectionState {
  /// Not connected to the WebSocket server
  disconnected,
  
  /// Currently attempting to establish a connection
  connecting,
  
  /// Successfully connected to the WebSocket server
  connected,
  
  /// Connection error occurred
  error,
}
