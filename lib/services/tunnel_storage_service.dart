import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import '../models/tunnel.dart';

/// Service for storing and retrieving tunnels using Hive
class TunnelStorageService {
  static const String _boxName = 'tunnels';
  final Logger _logger = Logger();
  
  Box<String>? _box;

  /// Initialize the storage service
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<String>(_boxName);
      _logger.i('TunnelStorageService initialized with ${_box!.length} tunnels');
    }
  }

  /// Ensure the box is initialized
  Future<Box<String>> _ensureBox() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
    return _box!;
  }

  /// Get all stored tunnels
  Future<List<Tunnel>> getAllTunnels() async {
    final box = await _ensureBox();
    final tunnels = <Tunnel>[];
    
    for (final key in box.keys) {
      try {
        final json = box.get(key);
        if (json != null) {
          final tunnel = Tunnel.fromJson(jsonDecode(json));
          tunnels.add(tunnel);
        }
      } catch (e) {
        _logger.e('Error loading tunnel $key: $e');
      }
    }
    
    // Sort by name
    tunnels.sort((a, b) => a.name.compareTo(b.name));
    return tunnels;
  }

  /// Get a tunnel by ID
  Future<Tunnel?> getTunnel(String id) async {
    final box = await _ensureBox();
    final json = box.get(id);
    
    if (json == null) return null;
    
    try {
      return Tunnel.fromJson(jsonDecode(json));
    } catch (e) {
      _logger.e('Error parsing tunnel $id: $e');
      return null;
    }
  }

  /// Save a tunnel (create or update)
  Future<void> saveTunnel(Tunnel tunnel) async {
    final box = await _ensureBox();
    final json = jsonEncode(tunnel.toJson());
    await box.put(tunnel.id, json);
    _logger.i('Saved tunnel: ${tunnel.name} (${tunnel.id})');
  }

  /// Delete a tunnel by ID
  Future<void> deleteTunnel(String id) async {
    final box = await _ensureBox();
    await box.delete(id);
    _logger.i('Deleted tunnel: $id');
  }

  /// Check if a tunnel with the given name exists
  Future<bool> tunnelExistsWithName(String name) async {
    final tunnels = await getAllTunnels();
    return tunnels.any((t) => t.name.toLowerCase() == name.toLowerCase());
  }

  /// Generate a unique tunnel name
  Future<String> generateUniqueName(String baseName) async {
    if (!await tunnelExistsWithName(baseName)) {
      return baseName;
    }
    
    int counter = 1;
    String newName;
    do {
      newName = '$baseName ($counter)';
      counter++;
    } while (await tunnelExistsWithName(newName));
    
    return newName;
  }

  /// Get the count of stored tunnels
  Future<int> getTunnelCount() async {
    final box = await _ensureBox();
    return box.length;
  }

  /// Clear all stored tunnels
  Future<void> clearAll() async {
    final box = await _ensureBox();
    await box.clear();
    _logger.w('Cleared all tunnels');
  }

  /// Export all tunnels to JSON string
  Future<String> exportAll() async {
    final tunnels = await getAllTunnels();
    return jsonEncode(tunnels.map((t) => t.toJson()).toList());
  }

  /// Import tunnels from JSON string
  Future<int> importFromJson(String jsonString) async {
    try {
      final List<dynamic> list = jsonDecode(jsonString);
      int count = 0;
      
      for (final item in list) {
        try {
          final tunnel = Tunnel.fromJson(item);
          await saveTunnel(tunnel);
          count++;
        } catch (e) {
          _logger.e('Error importing tunnel: $e');
        }
      }
      
      return count;
    } catch (e) {
      _logger.e('Error parsing import JSON: $e');
      return 0;
    }
  }

  /// Close the storage
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
