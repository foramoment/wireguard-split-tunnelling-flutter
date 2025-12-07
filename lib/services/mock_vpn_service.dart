import 'dart:async';
import 'dart:math';

import '../models/tunnel.dart';
import '../models/connection_status.dart';
import 'vpn_connection_service.dart';

/// Mock implementation of VpnConnectionService for UI testing
/// 
/// Simulates VPN connection behavior without actually connecting.
/// Useful for development and UI testing on platforms where
/// real VPN implementation is not yet available.
class MockVpnConnectionService implements VpnConnectionService {
  final _stateController = StreamController<VpnConnectionState>.broadcast();
  final _statsController = StreamController<VpnStatistics>.broadcast();
  final _random = Random();
  
  VpnConnectionState _currentState = VpnConnectionState.disconnected;
  String? _activeTunnelId;
  Timer? _statsTimer;
  int _rxBytes = 0;
  int _txBytes = 0;
  DateTime? _connectedAt;

  @override
  VpnConnectionState get currentState => _currentState;

  @override
  Stream<VpnConnectionState> get stateStream => _stateController.stream;

  @override
  Stream<VpnStatistics> get statisticsStream => _statsController.stream;

  @override
  String? get activeTunnelId => _activeTunnelId;

  void _setState(VpnConnectionState state) {
    _currentState = state;
    _stateController.add(state);
  }

  @override
  Future<ConnectionResult> connect(Tunnel tunnel) async {
    if (_currentState == VpnConnectionState.connected ||
        _currentState == VpnConnectionState.connecting) {
      return const ConnectionResult.failure(
        'Already connected or connecting',
        errorCode: 'ALREADY_CONNECTED',
      );
    }

    _activeTunnelId = tunnel.id;
    _setState(VpnConnectionState.connecting);

    // Simulate connection delay (1-2 seconds)
    await Future.delayed(Duration(milliseconds: 1000 + _random.nextInt(1000)));

    // Simulate occasional connection failures (10% chance)
    if (_random.nextInt(10) == 0) {
      _activeTunnelId = null;
      _setState(VpnConnectionState.error);
      await Future.delayed(const Duration(milliseconds: 500));
      _setState(VpnConnectionState.disconnected);
      return const ConnectionResult.failure(
        'Connection timed out',
        errorCode: 'TIMEOUT',
      );
    }

    // Success!
    _connectedAt = DateTime.now();
    _rxBytes = 0;
    _txBytes = 0;
    _setState(VpnConnectionState.connected);
    
    // Start simulating traffic
    _startStatsSimulation();

    return const ConnectionResult.success();
  }

  @override
  Future<ConnectionResult> disconnect() async {
    if (_currentState == VpnConnectionState.disconnected) {
      return const ConnectionResult.failure(
        'Not connected',
        errorCode: 'NOT_CONNECTED',
      );
    }

    _setState(VpnConnectionState.disconnecting);
    _stopStatsSimulation();

    // Simulate disconnect delay
    await Future.delayed(const Duration(milliseconds: 500));

    _activeTunnelId = null;
    _connectedAt = null;
    _rxBytes = 0;
    _txBytes = 0;
    _setState(VpnConnectionState.disconnected);

    return const ConnectionResult.success();
  }

  void _startStatsSimulation() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentState == VpnConnectionState.connected) {
        // Simulate traffic (random bytes per second)
        _rxBytes += _random.nextInt(50000) + 1000;
        _txBytes += _random.nextInt(10000) + 500;
        
        _statsController.add(VpnStatistics(
          rxBytes: _rxBytes,
          txBytes: _txBytes,
          lastHandshake: DateTime.now().subtract(
            Duration(seconds: _random.nextInt(120)),
          ),
          rtt: Duration(milliseconds: 10 + _random.nextInt(100)),
        ));
      }
    });
  }

  void _stopStatsSimulation() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  @override
  Future<VpnStatistics?> getStatistics() async {
    if (_currentState != VpnConnectionState.connected) {
      return null;
    }
    
    return VpnStatistics(
      rxBytes: _rxBytes,
      txBytes: _txBytes,
      lastHandshake: DateTime.now(),
      rtt: Duration(milliseconds: 10 + _random.nextInt(100)),
    );
  }

  @override
  Future<bool> isServiceAvailable() async {
    // Mock is always available
    return true;
  }

  @override
  Future<bool> requestPermissions() async {
    // Simulate permission request delay
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<({String privateKey, String publicKey})> generateKeyPair() async {
    // Generate mock base64-like keys (not real WireGuard keys!)
    String generateFakeKey() {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
      return List.generate(43, (_) => chars[_random.nextInt(chars.length)]).join() + '=';
    }

    await Future.delayed(const Duration(milliseconds: 100));
    
    return (
      privateKey: generateFakeKey(),
      publicKey: generateFakeKey(),
    );
  }

  @override
  void dispose() {
    _stopStatsSimulation();
    _stateController.close();
    _statsController.close();
  }
}
