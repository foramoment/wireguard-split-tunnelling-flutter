/// Connection state enumeration
enum ConnectionState {
  /// Not connected to any tunnel
  disconnected,

  /// Currently establishing connection
  connecting,

  /// Successfully connected
  connected,

  /// Disconnecting from tunnel
  disconnecting,

  /// Connection failed with error
  error,
}

/// Represents the current connection status and statistics
class ConnectionStatus {
  /// Current connection state
  final ConnectionState state;

  /// ID of the connected tunnel (null if disconnected)
  final String? tunnelId;

  /// Name of the connected tunnel
  final String? tunnelName;

  /// Error message if state is error
  final String? errorMessage;

  /// Connection start time
  final DateTime? connectedAt;

  /// Total bytes received
  final int rxBytes;

  /// Total bytes sent
  final int txBytes;

  /// Last handshake timestamp
  final DateTime? lastHandshake;

  /// Current endpoint address
  final String? endpoint;

  const ConnectionStatus({
    this.state = ConnectionState.disconnected,
    this.tunnelId,
    this.tunnelName,
    this.errorMessage,
    this.connectedAt,
    this.rxBytes = 0,
    this.txBytes = 0,
    this.lastHandshake,
    this.endpoint,
  });

  /// Create a disconnected status
  factory ConnectionStatus.disconnected() {
    return const ConnectionStatus(state: ConnectionState.disconnected);
  }

  /// Create a connecting status
  factory ConnectionStatus.connecting(String tunnelId, String tunnelName) {
    return ConnectionStatus(
      state: ConnectionState.connecting,
      tunnelId: tunnelId,
      tunnelName: tunnelName,
    );
  }

  /// Create a connected status
  factory ConnectionStatus.connected({
    required String tunnelId,
    required String tunnelName,
    String? endpoint,
  }) {
    return ConnectionStatus(
      state: ConnectionState.connected,
      tunnelId: tunnelId,
      tunnelName: tunnelName,
      connectedAt: DateTime.now(),
      endpoint: endpoint,
    );
  }

  /// Create an error status
  factory ConnectionStatus.error(String message) {
    return ConnectionStatus(
      state: ConnectionState.error,
      errorMessage: message,
    );
  }

  /// Create a copy with updated statistics
  ConnectionStatus copyWith({
    ConnectionState? state,
    String? tunnelId,
    String? tunnelName,
    String? errorMessage,
    DateTime? connectedAt,
    int? rxBytes,
    int? txBytes,
    DateTime? lastHandshake,
    String? endpoint,
  }) {
    return ConnectionStatus(
      state: state ?? this.state,
      tunnelId: tunnelId ?? this.tunnelId,
      tunnelName: tunnelName ?? this.tunnelName,
      errorMessage: errorMessage ?? this.errorMessage,
      connectedAt: connectedAt ?? this.connectedAt,
      rxBytes: rxBytes ?? this.rxBytes,
      txBytes: txBytes ?? this.txBytes,
      lastHandshake: lastHandshake ?? this.lastHandshake,
      endpoint: endpoint ?? this.endpoint,
    );
  }

  /// Check if currently connected
  bool get isConnected => state == ConnectionState.connected;

  /// Check if currently connecting
  bool get isConnecting => state == ConnectionState.connecting;

  /// Check if disconnected
  bool get isDisconnected => state == ConnectionState.disconnected;

  /// Check if in error state
  bool get hasError => state == ConnectionState.error;

  /// Check if busy (connecting or disconnecting)
  bool get isBusy =>
      state == ConnectionState.connecting ||
      state == ConnectionState.disconnecting;

  /// Get connection duration
  Duration? get connectionDuration {
    if (connectedAt == null || !isConnected) return null;
    return DateTime.now().difference(connectedAt!);
  }

  /// Get formatted connection duration string
  String get connectionDurationString {
    final duration = connectionDuration;
    if (duration == null) return '--:--:--';

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  /// Get human-readable bytes string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Get formatted received bytes
  String get rxBytesFormatted => _formatBytes(rxBytes);

  /// Get formatted sent bytes
  String get txBytesFormatted => _formatBytes(txBytes);

  /// Get state display name
  String get stateDisplayName {
    switch (state) {
      case ConnectionState.disconnected:
        return 'Disconnected';
      case ConnectionState.connecting:
        return 'Connecting...';
      case ConnectionState.connected:
        return 'Connected';
      case ConnectionState.disconnecting:
        return 'Disconnecting...';
      case ConnectionState.error:
        return 'Error';
    }
  }

  @override
  String toString() =>
      'ConnectionStatus(state: $state, tunnel: $tunnelName, rx: $rxBytesFormatted, tx: $txBytesFormatted)';
}
