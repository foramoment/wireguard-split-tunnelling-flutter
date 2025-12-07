import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/settings_provider.dart';
import 'providers/system_tray_provider.dart';
import 'providers/vpn_connection_provider.dart';

/// Main application widget
class WgClientApp extends ConsumerStatefulWidget {
  const WgClientApp({super.key});

  @override
  ConsumerState<WgClientApp> createState() => _WgClientAppState();
}

class _WgClientAppState extends ConsumerState<WgClientApp> with WindowListener {
  bool _trayInitialized = false;
  
  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.addListener(this);
    }
  }
  
  @override
  void dispose() {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }
  
  // Handle window close - minimize to tray instead of closing
  @override
  void onWindowClose() async {
    // Check if we want to minimize to tray or really close
    // For now, just hide the window (user can quit from tray menu)
    await windowManager.hide();
  }
  
  void _initSystemTray() {
    if (_trayInitialized) return;
    _trayInitialized = true;
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initializeSystemTray(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch theme mode from settings
    final themeMode = ref.watch(themeModeProvider);
    
    // Watch connection status to update tray
    final connectionStatus = ref.watch(vpnConnectionProvider);
    
    // Update tray when connection status changes
    final trayService = ref.read(systemTrayServiceProvider);
    if (trayService != null) {
      // Initialize tray on first build
      _initSystemTray();
      
      // Update tray state
      trayService.updateState(
        connectionStatus.state,
        tunnelName: connectionStatus.tunnelName,
      );
    }

    return MaterialApp.router(
      title: 'WireGuard Client',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
