import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection_status.dart';

/// Provider for the current connection status
final connectionStatusProvider = 
    StateNotifierProvider<ConnectionStatusNotifier, ConnectionStatus>((ref) {
  return ConnectionStatusNotifier();
});

/// State notifier for connection status
class ConnectionStatusNotifier extends StateNotifier<ConnectionStatus> {
  ConnectionStatusNotifier() : super(ConnectionStatus.disconnected());

  /// Start connecting to a tunnel
  void startConnecting(String tunnelId, String tunnelName) {
    state = ConnectionStatus.connecting(tunnelId, tunnelName);
  }

  /// Mark as connected
  void setConnected({
    required String tunnelId,
    required String tunnelName,
    String? endpoint,
  }) {
    state = ConnectionStatus.connected(
      tunnelId: tunnelId,
      tunnelName: tunnelName,
      endpoint: endpoint,
    );
  }

  /// Mark as disconnected
  void setDisconnected() {
    state = ConnectionStatus.disconnected();
  }

  /// Set error state
  void setError(String message) {
    state = ConnectionStatus.error(message);
  }

  /// Update statistics
  void updateStats({
    int? rxBytes,
    int? txBytes,
    DateTime? lastHandshake,
  }) {
    if (!state.isConnected) return;
    
    state = state.copyWith(
      rxBytes: rxBytes,
      txBytes: txBytes,
      lastHandshake: lastHandshake,
    );
  }

  /// Start disconnecting
  void startDisconnecting() {
    state = state.copyWith(state: ConnectionState.disconnecting);
  }
}

/// Provider for active tunnel ID
final activeTunnelIdProvider = Provider<String?>((ref) {
  final status = ref.watch(connectionStatusProvider);
  return status.tunnelId;
});

/// Provider to check if any tunnel is connected
final isConnectedProvider = Provider<bool>((ref) {
  final status = ref.watch(connectionStatusProvider);
  return status.isConnected;
});

/// Provider to check if connection is in progress
final isConnectingProvider = Provider<bool>((ref) {
  final status = ref.watch(connectionStatusProvider);
  return status.isBusy;
});
