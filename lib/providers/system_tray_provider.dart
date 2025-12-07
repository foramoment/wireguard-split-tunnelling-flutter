import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../services/system_tray_service.dart';
import 'vpn_connection_provider.dart';
import 'tunnel_provider.dart';

/// Provider for the system tray service
final systemTrayServiceProvider = Provider<SystemTrayService?>((ref) {
  // Only create on desktop platforms
  if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
    return null;
  }
  
  final service = SystemTrayService();
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Controller provider that manages system tray state based on VPN connection
final systemTrayControllerProvider = Provider<void>((ref) {
  final trayService = ref.watch(systemTrayServiceProvider);
  if (trayService == null) return;
  
  // Watch connection status and update tray
  final connectionStatus = ref.watch(vpnConnectionProvider);
  
  trayService.updateState(
    connectionStatus.state,
    tunnelName: connectionStatus.tunnelName,
  );
});

/// Initialize system tray with callbacks
/// Call this from main.dart after Riverpod is set up
Future<void> initializeSystemTray(WidgetRef ref) async {
  final trayService = ref.read(systemTrayServiceProvider);
  if (trayService == null) return;
  
  // Set up callbacks
  trayService.onToggleWindow = () async {
    // Toggle window visibility
    final isVisible = await windowManager.isVisible();
    if (isVisible) {
      await windowManager.hide();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  };
  
  trayService.onConnect = () async {
    // Connect to the first available tunnel
    final tunnelsAsyncValue = ref.read(tunnelsProvider);
    
    // Extract the list from AsyncValue
    final tunnels = tunnelsAsyncValue.valueOrNull;
    if (tunnels != null && tunnels.isNotEmpty) {
      final vpnNotifier = ref.read(vpnConnectionProvider.notifier);
      await vpnNotifier.connect(tunnels.first);
    }
  };
  
  trayService.onDisconnect = () async {
    final vpnNotifier = ref.read(vpnConnectionProvider.notifier);
    await vpnNotifier.disconnect();
  };
  
  trayService.onQuit = () async {
    // Disconnect VPN before quitting
    final connectionStatus = ref.read(vpnConnectionProvider);
    if (connectionStatus.isConnected) {
      final vpnNotifier = ref.read(vpnConnectionProvider.notifier);
      await vpnNotifier.disconnect();
    }
    await windowManager.destroy();
  };
  
  // Initialize tray
  await trayService.init();
  
  // Initial state update
  final connectionStatus = ref.read(vpnConnectionProvider);
  await trayService.updateState(
    connectionStatus.state,
    tunnelName: connectionStatus.tunnelName,
  );
}
