import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../models/split_tunnel_config.dart';

/// Service for storing split tunneling configurations
class SplitTunnelStorageService {
  static const String _boxName = 'split_tunnel_configs';
  final Logger _logger = Logger();
  
  Box<String>? _box;

  /// Initialize the storage service
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<String>(_boxName);
      _logger.i('SplitTunnelStorageService initialized');
    }
  }

  /// Ensure the box is initialized
  Future<Box<String>> _ensureBox() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
    return _box!;
  }

  /// Get a split tunnel config by ID
  Future<SplitTunnelConfig?> getConfig(String id) async {
    final box = await _ensureBox();
    final json = box.get(id);
    
    if (json == null) return null;
    
    try {
      return SplitTunnelConfig.fromJson(jsonDecode(json));
    } catch (e) {
      _logger.e('Error parsing split tunnel config $id: $e');
      return null;
    }
  }

  /// Get or create a config for a tunnel
  Future<SplitTunnelConfig> getOrCreateConfig(String tunnelId) async {
    var config = await getConfig(tunnelId);
    if (config == null) {
      config = SplitTunnelConfig.defaultConfig(tunnelId);
      await saveConfig(config);
    }
    return config;
  }

  /// Save a split tunnel config
  Future<void> saveConfig(SplitTunnelConfig config) async {
    final box = await _ensureBox();
    final json = jsonEncode(config.toJson());
    await box.put(config.id, json);
    _logger.i('Saved split tunnel config: ${config.id}');
  }

  /// Delete a split tunnel config
  Future<void> deleteConfig(String id) async {
    final box = await _ensureBox();
    await box.delete(id);
    _logger.i('Deleted split tunnel config: $id');
  }

  /// Get all configs
  Future<List<SplitTunnelConfig>> getAllConfigs() async {
    final box = await _ensureBox();
    final configs = <SplitTunnelConfig>[];
    
    for (final key in box.keys) {
      try {
        final json = box.get(key);
        if (json != null) {
          configs.add(SplitTunnelConfig.fromJson(jsonDecode(json)));
        }
      } catch (e) {
        _logger.e('Error loading split tunnel config $key: $e');
      }
    }
    
    return configs;
  }

  /// Close the storage
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
