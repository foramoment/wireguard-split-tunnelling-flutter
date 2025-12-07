import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../models/tunnel.dart';
import '../models/connection_status.dart';
import 'vpn_connection_service.dart';

/// Windows implementation of VPN connection service
/// 
/// Uses the installed WireGuard Windows application via CLI:
/// - wireguard.exe for tunnel service management
/// - wg.exe for statistics and key generation
class WindowsVpnService implements VpnConnectionService {
  final Logger _logger = Logger();
  
  // Stream controllers
  final _stateController = StreamController<VpnConnectionState>.broadcast();
  final _statsController = StreamController<VpnStatistics>.broadcast();
  
  // State
  VpnConnectionState _currentState = VpnConnectionState.disconnected;
  String? _activeTunnelId;
  String? _activeTunnelName;
  Timer? _statsTimer;
  
  // Paths to WireGuard executables
  String? _wireguardPath;
  String? _wgPath;
  
  // Config directory (where we store .conf files)
  String? _configDir;

  WindowsVpnService() {
    _initPaths();
  }
  
  Future<void> _initPaths() async {
    // Try to find WireGuard installation
    final programFiles = Platform.environment['ProgramFiles'] ?? r'C:\Program Files';
    final wireguardDir = path.join(programFiles, 'WireGuard');
    
    _wireguardPath = path.join(wireguardDir, 'wireguard.exe');
    _wgPath = path.join(wireguardDir, 'wg.exe');
    
    // Create config directory in app data
    final appDir = await getApplicationSupportDirectory();
    _configDir = path.join(appDir.path, 'tunnels');
    await Directory(_configDir!).create(recursive: true);
    
    _logger.i('WireGuard path: $_wireguardPath');
    _logger.i('Config dir: $_configDir');
    
    // Check for any currently active tunnels
    await _checkForActiveTunnel();
  }
  
  /// Check if any WireGuard tunnel is currently active
  Future<void> _checkForActiveTunnel() async {
    if (_wgPath == null) return;
    
    try {
      final result = await Process.run(_wgPath!, ['show', 'interfaces']);
      final interfaces = (result.stdout as String).trim();
      
      if (interfaces.isNotEmpty) {
        // There's an active tunnel!
        final tunnelName = interfaces.split(RegExp(r'\s+')).first;
        _logger.i('Found active tunnel: $tunnelName');
        
        _activeTunnelName = tunnelName;
        _updateState(VpnConnectionState.connected);
        _startStatsPolling();
      }
    } catch (e) {
      _logger.w('Failed to check for active tunnels: $e');
    }
  }

  @override
  VpnConnectionState get currentState => _currentState;

  @override
  Stream<VpnConnectionState> get stateStream => _stateController.stream;

  @override
  Stream<VpnStatistics> get statisticsStream => _statsController.stream;

  @override
  String? get activeTunnelId => _activeTunnelId;

  @override
  Future<bool> isServiceAvailable() async {
    await _ensurePaths();
    
    if (_wireguardPath == null) return false;
    
    final wireguardExists = await File(_wireguardPath!).exists();
    final wgExists = _wgPath != null ? await File(_wgPath!).exists() : false;
    
    _logger.i('WireGuard available: $wireguardExists, wg available: $wgExists');
    return wireguardExists;
  }

  @override
  Future<bool> requestPermissions() async {
    // Windows doesn't need runtime permissions, but needs admin for tunnel service
    // The elevation will be requested by wireguard.exe itself
    return true;
  }

  @override
  Future<ConnectionResult> connect(Tunnel tunnel) async {
    await _ensurePaths();
    
    if (_currentState == VpnConnectionState.connected || 
        _currentState == VpnConnectionState.connecting) {
      // Already connected or connecting
      if (_activeTunnelId == tunnel.id) {
        return const ConnectionResult.success();
      }
      // Disconnect from current tunnel first
      await disconnect();
    }
    
    _updateState(VpnConnectionState.connecting);
    _activeTunnelId = tunnel.id;
    _activeTunnelName = tunnel.name;
    
    try {
      // 1. Generate .conf file
      final confPath = await _generateConfigFile(tunnel);
      _logger.i('Generated config file: $confPath');
      
      // 2. Install tunnel service with UAC elevation
      final result = await _installTunnelService(confPath);
      
      if (!result.success) {
        _updateState(VpnConnectionState.disconnected);
        _activeTunnelId = null;
        _activeTunnelName = null;
        return result;
      }
      
      // 3. Wait for tunnel service to start and verify with retries
      bool isActive = false;
      for (int attempt = 0; attempt < 5; attempt++) {
        await Future.delayed(const Duration(seconds: 1));
        isActive = await _isTunnelActive(tunnel.name);
        _logger.d('Connection check attempt ${attempt + 1}: active=$isActive');
        if (isActive) break;
      }
      
      if (isActive) {
        _updateState(VpnConnectionState.connected);
        _startStatsPolling();
        return const ConnectionResult.success();
      } else {
        _updateState(VpnConnectionState.error);
        await Future.delayed(const Duration(milliseconds: 500));
        _updateState(VpnConnectionState.disconnected);
        return const ConnectionResult.failure('Tunnel did not connect');
      }
      
    } catch (e, stack) {
      _logger.e('Connection error', error: e, stackTrace: stack);
      _updateState(VpnConnectionState.error);
      _activeTunnelId = null;
      _activeTunnelName = null;
      return ConnectionResult.failure(e.toString());
    }
  }

  @override
  Future<ConnectionResult> disconnect() async {
    if (_currentState == VpnConnectionState.disconnected) {
      return const ConnectionResult.success();
    }
    
    _updateState(VpnConnectionState.disconnecting);
    _stopStatsPolling();
    
    try {
      if (_activeTunnelName != null) {
        await _uninstallTunnelService(_activeTunnelName!);
      }
      
      _updateState(VpnConnectionState.disconnected);
      _activeTunnelId = null;
      _activeTunnelName = null;
      
      return const ConnectionResult.success();
      
    } catch (e, stack) {
      _logger.e('Disconnect error', error: e, stackTrace: stack);
      // Force disconnect state anyway
      _updateState(VpnConnectionState.disconnected);
      _activeTunnelId = null;
      _activeTunnelName = null;
      return ConnectionResult.failure(e.toString());
    }
  }

  @override
  Future<VpnStatistics?> getStatistics() async {
    if (_currentState != VpnConnectionState.connected || _activeTunnelName == null) {
      return null;
    }
    
    try {
      return await _fetchStatistics(_activeTunnelName!);
    } catch (e) {
      _logger.w('Failed to get statistics: $e');
      return null;
    }
  }

  @override
  Future<({String privateKey, String publicKey})> generateKeyPair() async {
    await _ensurePaths();
    
    if (_wgPath == null || !await File(_wgPath!).exists()) {
      throw Exception('wg.exe not found');
    }
    
    // Generate private key
    final privResult = await Process.run(_wgPath!, ['genkey']);
    if (privResult.exitCode != 0) {
      throw Exception('Failed to generate private key: ${privResult.stderr}');
    }
    final privateKey = (privResult.stdout as String).trim();
    
    // Generate public key from private key via stdin
    final pubProcess = await Process.start(_wgPath!, ['pubkey']);
    pubProcess.stdin.writeln(privateKey);
    await pubProcess.stdin.close();
    
    final pubOutput = await pubProcess.stdout.transform(utf8.decoder).join();
    final exitCode = await pubProcess.exitCode;
    
    if (exitCode != 0) {
      throw Exception('Failed to generate public key');
    }
    
    final publicKey = pubOutput.trim();
    
    return (privateKey: privateKey, publicKey: publicKey);
  }

  @override
  void dispose() {
    _stopStatsPolling();
    _stateController.close();
    _statsController.close();
  }

  // ============ Private Methods ============

  Future<void> _ensurePaths() async {
    if (_configDir == null) {
      await _initPaths();
    }
  }

  void _updateState(VpnConnectionState newState) {
    _currentState = newState;
    _stateController.add(newState);
    _logger.d('VPN state changed: $newState');
  }

  /// Generate a WireGuard .conf file from the tunnel configuration
  Future<String> _generateConfigFile(Tunnel tunnel) async {
    final confContent = StringBuffer();
    
    // [Interface] section
    confContent.writeln('[Interface]');
    confContent.writeln('PrivateKey = ${tunnel.privateKey}');
    
    if (tunnel.addresses.isNotEmpty) {
      confContent.writeln('Address = ${tunnel.addresses.join(', ')}');
    }
    
    if (tunnel.dns != null && tunnel.dns!.isNotEmpty) {
      confContent.writeln('DNS = ${tunnel.dns!.join(', ')}');
    }
    
    if (tunnel.mtu != null) {
      confContent.writeln('MTU = ${tunnel.mtu}');
    }
    
    // [Peer] sections
    for (final peer in tunnel.peers) {
      confContent.writeln();
      confContent.writeln('[Peer]');
      confContent.writeln('PublicKey = ${peer.publicKey}');
      
      if (peer.presharedKey != null && peer.presharedKey!.isNotEmpty) {
        confContent.writeln('PresharedKey = ${peer.presharedKey}');
      }
      
      if (peer.endpoint != null && peer.endpoint!.isNotEmpty) {
        confContent.writeln('Endpoint = ${peer.endpoint}');
      }
      
      if (peer.allowedIPs.isNotEmpty) {
        confContent.writeln('AllowedIPs = ${peer.allowedIPs.join(', ')}');
      }
      
      if (peer.persistentKeepalive != null && peer.persistentKeepalive! > 0) {
        confContent.writeln('PersistentKeepalive = ${peer.persistentKeepalive}');
      }
    }
    
    // Write to file - use tunnel name as filename (sanitize for Windows)
    final safeName = tunnel.name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final confPath = path.join(_configDir!, '$safeName.conf');
    
    final file = File(confPath);
    await file.writeAsString(confContent.toString());
    
    return confPath;
  }

  /// Install tunnel as a Windows service (with UAC elevation)
  Future<ConnectionResult> _installTunnelService(String confPath) async {
    if (_wireguardPath == null) {
      return const ConnectionResult.failure('WireGuard not found');
    }
    
    try {
      // Create a temporary batch file to avoid PowerShell escaping issues
      final tempDir = await getTemporaryDirectory();
      final batPath = path.join(tempDir.path, 'wg_install.bat');
      final batFile = File(batPath);
      
      // Write the command to batch file
      final batContent = '@echo off\r\n"$_wireguardPath" /installtunnelservice "$confPath"\r\n';
      await batFile.writeAsString(batContent);
      
      _logger.i('Running elevated: wireguard.exe /installtunnelservice $confPath');
      
      // Use PowerShell to run the batch file as admin
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        'Start-Process',
        '-FilePath', batPath,
        '-Verb', 'RunAs',
        '-Wait',
      ]);
      
      _logger.i('PowerShell result: exit=${result.exitCode}');
      if ((result.stderr as String).isNotEmpty) {
        _logger.d('stderr: ${result.stderr}');
      }
      
      // Clean up
      try { await batFile.delete(); } catch (_) {}
      
      // If user cancelled UAC
      final stderr = result.stderr as String;
      if (stderr.contains('canceled') || stderr.contains('cancelled') ||
          stderr.contains('The operation was canceled')) {
        return const ConnectionResult.failure(
          'Please accept the UAC prompt to connect.',
          errorCode: 'UAC_CANCELLED',
        );
      }
      
      // We'll check tunnel status after to verify
      return const ConnectionResult.success();
      
    } catch (e) {
      _logger.e('Failed to run wireguard.exe: $e');
      return ConnectionResult.failure('Failed to run WireGuard: $e');
    }
  }

  /// Uninstall tunnel service (with UAC elevation)
  Future<void> _uninstallTunnelService(String tunnelName) async {
    if (_wireguardPath == null) return;
    
    try {
      // Create a temporary batch file
      final tempDir = await getTemporaryDirectory();
      final batPath = path.join(tempDir.path, 'wg_uninstall.bat');
      final batFile = File(batPath);
      
      // Sanitize tunnel name
      final safeName = tunnelName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      
      final batContent = '@echo off\r\n"$_wireguardPath" /uninstalltunnelservice $safeName\r\n';
      await batFile.writeAsString(batContent);
      
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        'Start-Process',
        '-FilePath', batPath,
        '-Verb', 'RunAs',
        '-Wait',
      ]);
      
      _logger.i('Uninstall tunnel result: exit=${result.exitCode}');
      
      // Clean up
      try { await batFile.delete(); } catch (_) {}
      
    } catch (e) {
      _logger.e('Failed to uninstall tunnel: $e');
    }
  }

  /// Check if tunnel is active
  Future<bool> _isTunnelActive(String tunnelName) async {
    if (_wgPath == null) return false;
    
    // Sanitize tunnel name (same as used for config file)
    final safeName = tunnelName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    
    try {
      // First try to show this specific tunnel
      var result = await Process.run(_wgPath!, ['show', safeName]);
      
      _logger.d('wg show $safeName: exit=${result.exitCode}');
      _logger.d('stdout: ${result.stdout}');
      
      if (result.exitCode == 0 && (result.stdout as String).trim().isNotEmpty) {
        return true;
      }
      
      // Fallback: check if tunnel is in the list of interfaces
      result = await Process.run(_wgPath!, ['show', 'interfaces']);
      final interfaces = (result.stdout as String).trim().split(RegExp(r'\s+'));
      _logger.d('wg interfaces: $interfaces');
      
      if (interfaces.contains(safeName)) {
        return true;
      }
      
      // Also check for Windows service
      final scResult = await Process.run('sc', ['query', 'WireGuardTunnel\$$safeName']);
      _logger.d('sc query result: ${scResult.exitCode}');
      
      if (scResult.exitCode == 0 && 
          (scResult.stdout as String).contains('RUNNING')) {
        return true;
      }
      
      return false;
      
    } catch (e) {
      _logger.w('Failed to check tunnel status: $e');
      return false;
    }
  }

  /// Fetch statistics from wg show
  Future<VpnStatistics> _fetchStatistics(String tunnelName) async {
    if (_wgPath == null) {
      return const VpnStatistics();
    }
    
    try {
      final result = await Process.run(_wgPath!, ['show', tunnelName, 'dump']);
      
      if (result.exitCode != 0) {
        return const VpnStatistics();
      }
      
      // Parse the dump output
      // Format: interface line, then peer lines
      // Peer line: public-key, preshared-key, endpoint, allowed-ips, latest-handshake, transfer-rx, transfer-tx, persistent-keepalive
      
      final output = (result.stdout as String).trim();
      final lines = output.split('\n');
      
      int totalRx = 0;
      int totalTx = 0;
      DateTime? lastHandshake;
      
      // Skip first line (interface), process peer lines
      for (int i = 1; i < lines.length; i++) {
        final parts = lines[i].split('\t');
        if (parts.length >= 7) {
          // latest-handshake is at index 4 (unix timestamp)
          final handshakeTs = int.tryParse(parts[4]) ?? 0;
          if (handshakeTs > 0) {
            final hs = DateTime.fromMillisecondsSinceEpoch(handshakeTs * 1000);
            if (lastHandshake == null || hs.isAfter(lastHandshake)) {
              lastHandshake = hs;
            }
          }
          
          // transfer-rx at index 5, transfer-tx at index 6
          totalRx += int.tryParse(parts[5]) ?? 0;
          totalTx += int.tryParse(parts[6]) ?? 0;
        }
      }
      
      return VpnStatistics(
        rxBytes: totalRx,
        txBytes: totalTx,
        lastHandshake: lastHandshake,
      );
      
    } catch (e) {
      _logger.w('Failed to fetch statistics: $e');
      return const VpnStatistics();
    }
  }

  void _startStatsPolling() {
    _stopStatsPolling();
    
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_currentState == VpnConnectionState.connected && _activeTunnelName != null) {
        final stats = await _fetchStatistics(_activeTunnelName!);
        _statsController.add(stats);
      }
    });
  }

  void _stopStatsPolling() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }
}
