import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tunnel.dart';
import '../models/connection_status.dart';
import '../services/vpn_connection_service.dart';
import '../services/mock_vpn_service.dart';
import 'tunnel_provider.dart';

/// Provider for the VPN connection service
/// 
/// Currently uses MockVpnConnectionService for development.
/// Will be replaced with platform-specific implementations:
/// - Windows: WindowsVpnService
/// - Android: AndroidVpnService
/// - macOS: MacOsVpnService
final vpnServiceProvider = Provider<VpnConnectionService>((ref) {
  final service = MockVpnConnectionService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for current VPN connection state
final vpnStateProvider = StreamProvider<VpnConnectionState>((ref) {
  final service = ref.watch(vpnServiceProvider);
  return service.stateStream;
});

/// Provider for VPN statistics (only emits when connected)
final vpnStatisticsProvider = StreamProvider<VpnStatistics>((ref) {
  final service = ref.watch(vpnServiceProvider);
  return service.statisticsStream;
});

/// Provider for the currently active tunnel
final activeTunnelProvider = FutureProvider<Tunnel?>((ref) async {
  final service = ref.watch(vpnServiceProvider);
  final tunnelId = service.activeTunnelId;
  
  if (tunnelId == null) return null;
  
  final storage = ref.watch(tunnelStorageServiceProvider);
  return storage.getTunnel(tunnelId);
});

/// Notifier for managing VPN connections
class VpnConnectionNotifier extends StateNotifier<ConnectionStatus> {
  final VpnConnectionService _service;
  final Ref _ref;
  StreamSubscription<VpnConnectionState>? _stateSubscription;
  StreamSubscription<VpnStatistics>? _statsSubscription;

  VpnConnectionNotifier(this._service, this._ref) 
      : super(ConnectionStatus.disconnected()) {
    _subscribeToStreams();
  }

  void _subscribeToStreams() {
    _stateSubscription = _service.stateStream.listen((vpnState) {
      state = state.copyWith(state: vpnState);
    });

    _statsSubscription = _service.statisticsStream.listen((stats) {
      state = state.copyWith(
        rxBytes: stats.rxBytes,
        txBytes: stats.txBytes,
        lastHandshake: stats.lastHandshake,
      );
    });
  }

  /// Connect to a tunnel
  Future<ConnectionResult> connect(Tunnel tunnel) async {
    state = ConnectionStatus.connecting(tunnel.id, tunnel.name);
    
    final result = await _service.connect(tunnel);
    
    if (result.success) {
      state = ConnectionStatus.connected(
        tunnelId: tunnel.id,
        tunnelName: tunnel.name,
        endpoint: tunnel.primaryEndpoint,
      );
    } else {
      state = ConnectionStatus.error(result.errorMessage ?? 'Unknown error');
      // Reset to disconnected after showing error briefly
      Future.delayed(const Duration(seconds: 2), () {
        if (state.hasError) {
          state = ConnectionStatus.disconnected();
        }
      });
    }
    
    return result;
  }

  /// Disconnect from current tunnel
  Future<ConnectionResult> disconnect() async {
    state = state.copyWith(state: VpnConnectionState.disconnecting);
    
    final result = await _service.disconnect();
    
    if (result.success) {
      state = ConnectionStatus.disconnected();
    }
    
    return result;
  }

  /// Toggle connection state
  Future<void> toggle(Tunnel tunnel) async {
    if (state.isConnected && state.tunnelId == tunnel.id) {
      await disconnect();
    } else if (state.isConnected && state.tunnelId != tunnel.id) {
      // Connected to different tunnel - switch
      await disconnect();
      await connect(tunnel);
    } else {
      await connect(tunnel);
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _statsSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for VPN connection management
final vpnConnectionProvider = StateNotifierProvider<VpnConnectionNotifier, ConnectionStatus>((ref) {
  final service = ref.watch(vpnServiceProvider);
  return VpnConnectionNotifier(service, ref);
});

/// Simple provider to check if currently connected
final isVpnConnectedProvider = Provider<bool>((ref) {
  final status = ref.watch(vpnConnectionProvider);
  return status.isConnected;
});

/// Simple provider to check if currently connecting/disconnecting
final isVpnBusyProvider = Provider<bool>((ref) {
  final status = ref.watch(vpnConnectionProvider);
  return status.isBusy;
});
