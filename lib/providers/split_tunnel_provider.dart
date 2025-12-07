import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/split_tunnel_config.dart';
import '../services/split_tunnel_storage_service.dart';

/// Provider for the split tunnel storage service
final splitTunnelStorageServiceProvider = Provider<SplitTunnelStorageService>((ref) {
  final service = SplitTunnelStorageService();
  ref.onDispose(() => service.close());
  return service;
});

/// Global split tunnel config ID for when no specific tunnel is selected
const globalSplitTunnelId = 'global';

/// Async provider family for split tunnel configs per tunnel
/// 
/// This properly loads the config from storage before returning
/// Usage: 
/// ```dart
/// final configAsync = ref.watch(splitTunnelConfigProvider(tunnelId));
/// configAsync.when(
///   data: (config) => ...,
///   loading: () => CircularProgressIndicator(),
///   error: (e, s) => Text('Error: $e'),
/// );
/// ```
final splitTunnelConfigProvider = AsyncNotifierProvider.family<
    SplitTunnelConfigNotifier, SplitTunnelConfig, String>(
  SplitTunnelConfigNotifier.new,
);

/// Notifier for managing split tunnel configuration
class SplitTunnelConfigNotifier extends FamilyAsyncNotifier<SplitTunnelConfig, String> {
  late final SplitTunnelStorageService _storage;

  @override
  Future<SplitTunnelConfig> build(String tunnelId) async {
    _storage = ref.watch(splitTunnelStorageServiceProvider);
    await _storage.init();
    return _storage.getOrCreateConfig(tunnelId);
  }

  /// Enable or disable split tunneling
  Future<void> setEnabled(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final updated = current.copyWith(enabled: enabled);
    state = AsyncData(updated);
    await _storage.saveConfig(updated);
  }

  /// Change split tunneling mode (exclude/include)
  Future<void> setMode(SplitTunnelMode mode) async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final updated = current.copyWith(mode: mode);
    state = AsyncData(updated);
    await _storage.saveConfig(updated);
  }

  /// Add an app to the config
  Future<void> addApp(AppInfo app) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.apps.any((a) => a.id == app.id)) return; // Already exists
    
    final updated = current.copyWith(apps: [...current.apps, app]);
    state = AsyncData(updated);
    await _storage.saveConfig(updated);
  }

  /// Remove an app from the config
  Future<void> removeApp(String appId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final updated = current.copyWith(
      apps: current.apps.where((a) => a.id != appId).toList(),
    );
    state = AsyncData(updated);
    await _storage.saveConfig(updated);
  }

  /// Add a folder to the config
  Future<void> addFolder(SplitTunnelFolder folder) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.folders.any((f) => f.path == folder.path)) return; // Already exists
    
    final updated = current.copyWith(folders: [...current.folders, folder]);
    state = AsyncData(updated);
    await _storage.saveConfig(updated);
  }

  /// Update a folder (e.g., after rescan)
  Future<void> updateFolder(SplitTunnelFolder folder) async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final folders = current.folders.map((f) {
      return f.id == folder.id ? folder : f;
    }).toList();
    
    final updated = current.copyWith(folders: folders);
    state = AsyncData(updated);
    await _storage.saveConfig(updated);
  }

  /// Remove a folder from the config
  Future<void> removeFolder(String folderId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final updated = current.copyWith(
      folders: current.folders.where((f) => f.id != folderId).toList(),
    );
    state = AsyncData(updated);
    await _storage.saveConfig(updated);
  }

  /// Clear all apps and folders
  Future<void> clearAll() async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final updated = current.copyWith(apps: [], folders: []);
    state = AsyncData(updated);
    await _storage.saveConfig(updated);
  }
}

/// Provider to check if split tunneling is enabled for a tunnel
final isSplitTunnelEnabledProvider = Provider.family<bool, String>((ref, tunnelId) {
  final configAsync = ref.watch(splitTunnelConfigProvider(tunnelId));
  return configAsync.valueOrNull?.enabled ?? false;
});

/// Provider to get total app count in split tunnel config
final splitTunnelAppCountProvider = Provider.family<int, String>((ref, tunnelId) {
  final configAsync = ref.watch(splitTunnelConfigProvider(tunnelId));
  return configAsync.valueOrNull?.totalAppCount ?? 0;
});

/// Global split tunnel config provider
final globalSplitTunnelConfigProvider = AsyncNotifierProvider<
    GlobalSplitTunnelConfigNotifier, SplitTunnelConfig>(
  GlobalSplitTunnelConfigNotifier.new,
);

/// Notifier for global split tunnel configuration
class GlobalSplitTunnelConfigNotifier extends AsyncNotifier<SplitTunnelConfig> {
  late final SplitTunnelStorageService _storage;

  @override
  Future<SplitTunnelConfig> build() async {
    _storage = ref.watch(splitTunnelStorageServiceProvider);
    await _storage.init();
    return _storage.getOrCreateConfig(globalSplitTunnelId);
  }

  /// Enable or disable split tunneling
  Future<void> setEnabled(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final updated = current.copyWith(enabled: enabled);
    state = AsyncData(updated);
    await _storage.saveConfig(updated);
  }

  /// Change split tunneling mode (exclude/include)
  Future<void> setMode(SplitTunnelMode mode) async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final updated = current.copyWith(mode: mode);
    state = AsyncData(updated);
    await _storage.saveConfig(updated);
  }

  /// Add an app to the config
  Future<void> addApp(AppInfo app) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.apps.any((a) => a.id == app.id)) return;
    
    final updated = current.copyWith(apps: [...current.apps, app]);
    state = AsyncData(updated);
    await _storage.saveConfig(updated);
  }

  /// Remove an app from the config
  Future<void> removeApp(String appId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final updated = current.copyWith(
      apps: current.apps.where((a) => a.id != appId).toList(),
    );
    state = AsyncData(updated);
    await _storage.saveConfig(updated);
  }

  /// Add a folder to the config
  Future<void> addFolder(SplitTunnelFolder folder) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.folders.any((f) => f.path == folder.path)) return;
    
    final updated = current.copyWith(folders: [...current.folders, folder]);
    state = AsyncData(updated);
    await _storage.saveConfig(updated);
  }

  /// Update a folder (e.g., after rescan)
  Future<void> updateFolder(SplitTunnelFolder folder) async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final folders = current.folders.map((f) {
      return f.id == folder.id ? folder : f;
    }).toList();
    
    final updated = current.copyWith(folders: folders);
    state = AsyncData(updated);
    await _storage.saveConfig(updated);
  }

  /// Remove a folder from the config
  Future<void> removeFolder(String folderId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final updated = current.copyWith(
      folders: current.folders.where((f) => f.id != folderId).toList(),
    );
    state = AsyncData(updated);
    await _storage.saveConfig(updated);
  }

  /// Clear all apps and folders
  Future<void> clearAll() async {
    final current = state.valueOrNull;
    if (current == null) return;
    
    final updated = current.copyWith(apps: [], folders: []);
    state = AsyncData(updated);
    await _storage.saveConfig(updated);
  }
}
