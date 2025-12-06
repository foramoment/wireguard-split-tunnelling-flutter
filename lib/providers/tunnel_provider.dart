import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tunnel.dart';
import '../services/tunnel_storage_service.dart';

/// Provider for the tunnel storage service
final tunnelStorageServiceProvider = Provider<TunnelStorageService>((ref) {
  return TunnelStorageService();
});

/// Provider for the list of all tunnels
final tunnelsProvider = StateNotifierProvider<TunnelsNotifier, AsyncValue<List<Tunnel>>>((ref) {
  final storage = ref.watch(tunnelStorageServiceProvider);
  return TunnelsNotifier(storage);
});

/// Provider for a single tunnel by ID
final tunnelProvider = FutureProvider.family<Tunnel?, String>((ref, id) async {
  final storage = ref.watch(tunnelStorageServiceProvider);
  return storage.getTunnel(id);
});

/// State notifier for managing tunnels
class TunnelsNotifier extends StateNotifier<AsyncValue<List<Tunnel>>> {
  final TunnelStorageService _storage;
  
  TunnelsNotifier(this._storage) : super(const AsyncValue.loading()) {
    loadTunnels();
  }

  /// Load all tunnels from storage
  Future<void> loadTunnels() async {
    state = const AsyncValue.loading();
    try {
      await _storage.init();
      final tunnels = await _storage.getAllTunnels();
      state = AsyncValue.data(tunnels);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Add a new tunnel
  Future<void> addTunnel(Tunnel tunnel) async {
    try {
      await _storage.saveTunnel(tunnel);
      await loadTunnels();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update an existing tunnel
  Future<void> updateTunnel(Tunnel tunnel) async {
    try {
      await _storage.saveTunnel(tunnel);
      await loadTunnels();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Delete a tunnel by ID
  Future<void> deleteTunnel(String id) async {
    try {
      await _storage.deleteTunnel(id);
      await loadTunnels();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Import a tunnel from config content
  Future<Tunnel?> importFromConfig(String configContent, {String? name}) async {
    try {
      // Import will be done via ConfigParser utility
      // This is a placeholder - will be connected to the parser
      await loadTunnels();
      return null;
    } catch (e) {
      return null;
    }
  }
}
