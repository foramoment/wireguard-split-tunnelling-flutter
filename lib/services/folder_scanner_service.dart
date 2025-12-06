import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';

import '../models/split_tunnel_config.dart';

/// Service for scanning folders for executable files
class FolderScannerService {
  final Logger _logger = Logger();

  /// Scan a directory for executable files
  /// Returns list of executable paths found
  Future<List<String>> scanFolder(String folderPath) async {
    final executables = <String>[];
    final dir = Directory(folderPath);

    if (!await dir.exists()) {
      _logger.w('Directory does not exist: $folderPath');
      return executables;
    }

    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = path.extension(entity.path).toLowerCase();
          
          // Windows executables
          if (Platform.isWindows && ext == '.exe') {
            executables.add(entity.path);
          }
          
          // macOS apps
          if (Platform.isMacOS && ext == '.app') {
            executables.add(entity.path);
          }
          
          // Linux executables (check if executable permission)
          if (Platform.isLinux) {
            try {
              final stat = await entity.stat();
              // Check if file has executable permission
              if (stat.mode & 0x49 != 0) { // 0x49 = 0111 in octal (x for u/g/o)
                executables.add(entity.path);
              }
            } catch (_) {
              // Skip files we can't stat
            }
          }
        }
      }
    } catch (e) {
      _logger.e('Error scanning folder $folderPath: $e');
    }

    _logger.i('Found ${executables.length} executables in $folderPath');
    return executables;
  }

  /// Create a SplitTunnelFolder from a directory path
  Future<SplitTunnelFolder> createFolderConfig(String folderPath) async {
    final name = path.basename(folderPath);
    final executables = await scanFolder(folderPath);
    
    // Extract just the filenames for display
    final appNames = executables
        .map((e) => path.basename(e))
        .toList();

    return SplitTunnelFolder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: folderPath,
      name: name,
      discoveredApps: appNames,
      lastScanned: DateTime.now(),
    );
  }

  /// Rescan an existing folder and update discovered apps
  Future<SplitTunnelFolder> rescanFolder(SplitTunnelFolder folder) async {
    final executables = await scanFolder(folder.path);
    final appNames = executables
        .map((e) => path.basename(e))
        .toList();

    return folder.copyWith(
      discoveredApps: appNames,
      lastScanned: DateTime.now(),
    );
  }

  /// Get full paths of executables from folder
  Future<List<String>> getFullExecutablePaths(SplitTunnelFolder folder) async {
    return await scanFolder(folder.path);
  }
}
