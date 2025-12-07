import '../models/tunnel.dart';
import '../models/connection_status.dart';

/// Statistics from an active VPN connection
class VpnStatistics {
  final int rxBytes;
  final int txBytes;
  final DateTime? lastHandshake;
  final Duration? rtt;

  const VpnStatistics({
    this.rxBytes = 0,
    this.txBytes = 0,
    this.lastHandshake,
    this.rtt,
  });

  VpnStatistics copyWith({
    int? rxBytes,
    int? txBytes,
    DateTime? lastHandshake,
    Duration? rtt,
  }) {
    return VpnStatistics(
      rxBytes: rxBytes ?? this.rxBytes,
      txBytes: txBytes ?? this.txBytes,
      lastHandshake: lastHandshake ?? this.lastHandshake,
      rtt: rtt ?? this.rtt,
    );
  }
}

/// Result of a connection attempt
class ConnectionResult {
  final bool success;
  final String? errorMessage;
  final String? errorCode;

  const ConnectionResult.success()
      : success = true,
        errorMessage = null,
        errorCode = null;

  const ConnectionResult.failure(this.errorMessage, {this.errorCode})
      : success = false;

  @override
  String toString() => success 
      ? 'ConnectionResult.success' 
      : 'ConnectionResult.failure($errorMessage)';
}

/// Abstract interface for VPN connection operations
/// 
/// Platform-specific implementations should extend this class:
/// - WindowsVpnService: Uses WireGuard Windows service/wg.exe
/// - AndroidVpnService: Uses VpnService + wireguard-android
/// - MacOsVpnService: Uses Network Extension + WireGuardKit
/// - LinuxVpnService: Uses wg-quick or direct kernel module
abstract class VpnConnectionService {
  /// Current connection status
  VpnConnectionState get currentState;

  /// Stream of connection state changes
  Stream<VpnConnectionState> get stateStream;

  /// Stream of connection statistics (updated periodically when connected)
  Stream<VpnStatistics> get statisticsStream;

  /// Currently connected tunnel ID (null if disconnected)
  String? get activeTunnelId;

  /// Connect to a tunnel
  /// 
  /// Returns [ConnectionResult] indicating success or failure
  Future<ConnectionResult> connect(Tunnel tunnel);

  /// Disconnect from the current tunnel
  Future<ConnectionResult> disconnect();

  /// Get current statistics (null if not connected)
  Future<VpnStatistics?> getStatistics();

  /// Check if VPN service is available on this platform
  Future<bool> isServiceAvailable();

  /// Request necessary permissions (e.g., VPN permission on Android)
  Future<bool> requestPermissions();

  /// Generate a new WireGuard keypair
  Future<({String privateKey, String publicKey})> generateKeyPair();

  /// Dispose resources
  void dispose();
}

/// Events that can occur during VPN connection
enum VpnEvent {
  connecting,
  connected,
  disconnecting,
  disconnected,
  reconnecting,
  handshakeComplete,
  error,
}

/// Listener for VPN events
typedef VpnEventListener = void Function(VpnEvent event, String? message);
