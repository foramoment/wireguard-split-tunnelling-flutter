import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/split_tunnel_config.dart';
import '../services/split_tunnel_storage_service.dart';

/// Provider for the split tunnel storage service
final splitTunnelStorageServiceProvider = Provider<SplitTunnelStorageService>((ref) {
  final service = SplitTunnelStorageService();
  ref.onDispose(() => service.close());
  return service;
});

/// Notifier for managing split tunnel configuration
/// 
/// This is a family provider - each tunnel has its own split tunnel config
class SplitTunnelConfigNotifier extends StateNotifier<SplitTunnelConfig> {
  final SplitTunnelStorageService _storage;
  final String _tunnelId;
  bool _initialized = false;

  SplitTunnelConfigNotifier(this._storage, this._tunnelId)
      : super(SplitTunnelConfig.defaultConfig(_tunnelId));

  /// Initialize and load config from storage
  Future<void> initialize() async {
    if (_initialized) return;
    
    await _storage.init();
    final config = await _storage.getOrCreateConfig(_tunnelId);
    state = config;
    _initialized = true;
  }

  /// Enable or disable split tunneling
  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    await _save();
  }

  /// Change split tunneling mode (exclude/include)
  Future<void> setMode(SplitTunnelMode mode) async {
    state = state.copyWith(mode: mode);
    await _save();
  }

  /// Add an app to the config
  Future<void> addApp(AppInfo app) async {
    if (state.apps.any((a) => a.id == app.id)) return; // Already exists
    
    state = state.copyWith(apps: [...state.apps, app]);
    await _save();
  }

  /// Remove an app from the config
  Future<void> removeApp(String appId) async {
    state = state.copyWith(
      apps: state.apps.where((a) => a.id != appId).toList(),
    );
    await _save();
  }

  /// Add a folder to the config
  Future<void> addFolder(SplitTunnelFolder folder) async {
    if (state.folders.any((f) => f.path == folder.path)) return; // Already exists
    
    state = state.copyWith(folders: [...state.folders, folder]);
    await _save();
  }

  /// Update a folder (e.g., after rescan)
  Future<void> updateFolder(SplitTunnelFolder folder) async {
    final folders = state.folders.map((f) {
      return f.id == folder.id ? folder : f;
    }).toList();
    
    state = state.copyWith(folders: folders);
    await _save();
  }

  /// Remove a folder from the config
  Future<void> removeFolder(String folderId) async {
    state = state.copyWith(
      folders: state.folders.where((f) => f.id != folderId).toList(),
    );
    await _save();
  }

  /// Clear all apps and folders
  Future<void> clearAll() async {
    state = state.copyWith(apps: [], folders: []);
    await _save();
  }

  Future<void> _save() async {
    await _storage.saveConfig(state);
  }
}

/// Provider family for split tunnel configs per tunnel
/// 
/// Usage: 
/// ```dart
/// final config = ref.watch(splitTunnelConfigProvider(tunnelId));
/// ```
final splitTunnelConfigProvider = StateNotifierProvider.family<
    SplitTunnelConfigNotifier, SplitTunnelConfig, String>(
  (ref, tunnelId) {
    final storage = ref.watch(splitTunnelStorageServiceProvider);
    final notifier = SplitTunnelConfigNotifier(storage, tunnelId);
    // Initialize asynchronously
    notifier.initialize();
    return notifier;
  },
);

/// Provider to get split tunnel config for a specific tunnel
/// This is an async version that ensures initialization completes
final splitTunnelConfigFutureProvider = FutureProvider.family<SplitTunnelConfig, String>(
  (ref, tunnelId) async {
    final storage = ref.watch(splitTunnelStorageServiceProvider);
    await storage.init();
    return storage.getOrCreateConfig(tunnelId);
  },
);

/// Provider to check if split tunneling is enabled for a tunnel
final isSplitTunnelEnabledProvider = Provider.family<bool, String>((ref, tunnelId) {
  final config = ref.watch(splitTunnelConfigProvider(tunnelId));
  return config.enabled;
});

/// Provider to get total app count in split tunnel config
final splitTunnelAppCountProvider = Provider.family<int, String>((ref, tunnelId) {
  final config = ref.watch(splitTunnelConfigProvider(tunnelId));
  return config.totalAppCount;
});

/// Global split tunnel config for when no specific tunnel is selected
/// Uses a special ID 'global' for app-wide settings
const globalSplitTunnelId = 'global';

final globalSplitTunnelConfigProvider = StateNotifierProvider<
    SplitTunnelConfigNotifier, SplitTunnelConfig>(
  (ref) {
    final storage = ref.watch(splitTunnelStorageServiceProvider);
    final notifier = SplitTunnelConfigNotifier(storage, globalSplitTunnelId);
    notifier.initialize();
    return notifier;
  },
);
