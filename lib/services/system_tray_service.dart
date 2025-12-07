import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tray_manager/tray_manager.dart';

import '../models/connection_status.dart';

/// Callback type for tray menu actions
typedef TrayActionCallback = void Function();
typedef TrayToggleCallback = Future<void> Function();

/// Service to manage system tray icon and menu on desktop platforms
class SystemTrayService with TrayListener {
  // Callbacks for menu actions
  TrayToggleCallback? onToggleWindow;  // Toggle window visibility
  TrayActionCallback? onConnect;
  TrayActionCallback? onDisconnect;
  TrayActionCallback? onQuit;
  
  // Current state
  VpnConnectionState _currentState = VpnConnectionState.disconnected;
  String? _activeTunnelName;
  
  // Icon paths (will be populated on init)
  String? _iconDisconnected;
  String? _iconConnecting;
  String? _iconConnected;
  
  bool _initialized = false;
  
  /// Initialize the system tray
  Future<void> init() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return; // System tray is only supported on desktop platforms
    }
    
    if (_initialized) return;
    _initialized = true;
    
    // Extract icon assets to files (tray_manager needs file paths)
    await _extractIcons();
    
    // Add listener for tray events
    trayManager.addListener(this);
    
    // Set initial icon
    if (_iconDisconnected != null && _iconDisconnected!.isNotEmpty) {
      await trayManager.setIcon(_iconDisconnected!);
    }
    
    // Set tooltip
    await trayManager.setToolTip('WireGuard Client - Disconnected');
    
    // Set up menu
    await _updateMenu();
    
    debugPrint('System tray initialized');
  }
  
  /// Extract icon assets to temp directory
  Future<void> _extractIcons() async {
    final tempDir = await getTemporaryDirectory();
    final iconsDir = Directory(p.join(tempDir.path, 'wg_client_icons'));
    await iconsDir.create(recursive: true);
    
    _iconDisconnected = await _extractIcon(
      'assets/icons/tray_disconnected',
      iconsDir.path,
    );
    
    _iconConnecting = await _extractIcon(
      'assets/icons/tray_connecting',
      iconsDir.path,
    );
    
    _iconConnected = await _extractIcon(
      'assets/icons/tray_connected',
      iconsDir.path,
    );
    
    debugPrint('Extracted icons: disconnected=$_iconDisconnected');
  }
  
  /// Extract icon asset (preferring .ico on Windows)
  Future<String> _extractIcon(String assetBaseName, String targetDir) async {
    try {
      final fileName = p.basename(assetBaseName);
      
      // On Windows, try to find a native .ico asset first
      if (Platform.isWindows) {
        try {
          final icoAssetPath = '$assetBaseName.ico';
          final bytes = await rootBundle.load(icoAssetPath);
          final icoBytes = bytes.buffer.asUint8List();
          
          final targetPath = p.join(targetDir, '$fileName.ico');
          final file = File(targetPath);
          await file.writeAsBytes(icoBytes);
          
          final absolutePath = file.absolute.path;
          debugPrint('Using native ICO: $absolutePath (Size: ${icoBytes.length} bytes)');
          return absolutePath;
        } catch (e) {
          debugPrint('Native ICO not found ($assetBaseName.ico), falling back to PNG conversion');
        }
      }

      // Fallback: Load PNG
      final pngAssetPath = '$assetBaseName.png';
      final bytes = await rootBundle.load(pngAssetPath);
      final pngBytes = bytes.buffer.asUint8List();
      
      if (Platform.isWindows) {
        // Convert PNG to ICO
        final targetPath = p.join(targetDir, '$fileName.ico');
        final icoBytes = await _convertPngToIco(pngBytes);
        
        if (icoBytes != null) {
          final file = File(targetPath);
          await file.writeAsBytes(icoBytes);
          final absolutePath = file.absolute.path;
          debugPrint('Created ICO from PNG: $absolutePath');
          return absolutePath;
        }
      } 
      
      // Default/Fallback: Save as PNG (for non-Windows or conversion failure)
      final targetPath = p.join(targetDir, '$fileName.png');
      final file = File(targetPath);
      await file.writeAsBytes(pngBytes);
      return targetPath;

    } catch (e) {
      debugPrint('Failed to extract/convert asset $assetBaseName: $e');
      return '';
    }
  }
  
  /// Convert PNG bytes to ICO format
  Future<Uint8List?> _convertPngToIco(Uint8List pngBytes) async {
    try {
      // Decode PNG
      final image = img.decodePng(pngBytes);
      if (image == null) {
        debugPrint('Failed to decode PNG');
        return null;
      }
      
      // Resize to 32x32 for tray icon (standard size)
      final resized = img.copyResize(image, width: 32, height: 32);
      
      // Encode as ICO
      final icoBytes = img.encodeIco(resized);
      return Uint8List.fromList(icoBytes);
    } catch (e) {
      debugPrint('Failed to convert PNG to ICO: $e');
      return null;
    }
  }
  
  /// Update the tray state based on VPN connection status
  Future<void> updateState(VpnConnectionState state, {String? tunnelName}) async {
    if (!_initialized) return;
    
    _currentState = state;
    _activeTunnelName = tunnelName;
    
    String iconPath;
    String tooltip;
    
    switch (state) {
      case VpnConnectionState.connected:
        iconPath = _iconConnected ?? '';
        tooltip = tunnelName != null 
            ? 'Connected: $tunnelName' 
            : 'WireGuard Client - Connected';
      case VpnConnectionState.connecting:
      case VpnConnectionState.disconnecting:
        iconPath = _iconConnecting ?? '';
        tooltip = state == VpnConnectionState.connecting 
            ? 'Connecting...' 
            : 'Disconnecting...';
      case VpnConnectionState.disconnected:
      case VpnConnectionState.error:
        iconPath = _iconDisconnected ?? '';
        tooltip = 'WireGuard Client - Disconnected';
    }
    
    if (iconPath.isNotEmpty) {
      await trayManager.setIcon(iconPath);
    }
    await trayManager.setToolTip(tooltip);
    await _updateMenu();
  }
  
  /// Update the system tray context menu
  Future<void> _updateMenu() async {
    final isConnected = _currentState == VpnConnectionState.connected;
    final isConnecting = _currentState == VpnConnectionState.connecting;
    final isDisconnecting = _currentState == VpnConnectionState.disconnecting;
    final isBusy = isConnecting || isDisconnecting;
    
    // Status text
    String statusText;
    if (isConnected && _activeTunnelName != null) {
      statusText = '✓ Connected: $_activeTunnelName';
    } else if (isConnecting) {
      statusText = '⟳ Connecting...';
    } else if (isDisconnecting) {
      statusText = '⟳ Disconnecting...';
    } else {
      statusText = '○ Disconnected';
    }
    
    // Build menu
    final menu = Menu(
      items: [
        // Status (disabled, just for display)
        MenuItem(
          key: 'status',
          label: statusText,
          disabled: true,
        ),
        MenuItem.separator(),
        // Connect/Disconnect button
        if (isConnected)
          MenuItem(
            key: 'disconnect',
            label: 'Disconnect',
            disabled: isBusy,
          )
        else
          MenuItem(
            key: 'connect',
            label: 'Connect',
            disabled: isBusy,
          ),
        MenuItem.separator(),
        MenuItem(
          key: 'show_window',
          label: 'Show Window',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'quit',
          label: 'Quit',
        ),
      ],
    );
    
    await trayManager.setContextMenu(menu);
  }
  
  // TrayListener callbacks
  
  @override
  void onTrayIconMouseDown() {
    // Left click - toggle window visibility
    onToggleWindow?.call();
  }
  
  @override
  void onTrayIconRightMouseDown() {
    // Right click - show context menu
    trayManager.popUpContextMenu();
  }
  
  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        onToggleWindow?.call();
        break;
      case 'connect':
        onConnect?.call();
        break;
      case 'disconnect':
        onDisconnect?.call();
        break;
      case 'quit':
        onQuit?.call();
        break;
    }
  }
  
  /// Dispose the system tray
  void dispose() {
    if (_initialized) {
      trayManager.removeListener(this);
      trayManager.destroy();
    }
  }
}
