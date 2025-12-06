import 'package:json_annotation/json_annotation.dart';

part 'split_tunnel_config.g.dart';

/// Split tunneling mode
enum SplitTunnelMode {
  /// All traffic through VPN except listed apps (exclude mode)
  @JsonValue('exclude')
  exclude,

  /// Only listed apps through VPN (include mode)
  @JsonValue('include')
  include,
}

/// Information about an application for split tunneling
@JsonSerializable()
class AppInfo {
  /// Unique identifier (package name on mobile, exe path on desktop)
  final String id;

  /// Display name of the application
  final String name;

  /// Path to the executable (desktop only)
  final String? path;

  /// Package name (mobile only)
  final String? packageName;

  /// Whether this was added from a folder scan
  final bool fromFolder;

  /// Folder path if added via folder scan
  final String? folderPath;

  const AppInfo({
    required this.id,
    required this.name,
    this.path,
    this.packageName,
    this.fromFolder = false,
    this.folderPath,
  });

  factory AppInfo.fromJson(Map<String, dynamic> json) => _$AppInfoFromJson(json);
  Map<String, dynamic> toJson() => _$AppInfoToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppInfo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AppInfo(id: $id, name: $name)';
}

/// Folder configuration for split tunneling
@JsonSerializable()
class SplitTunnelFolder {
  /// Unique identifier
  final String id;

  /// Full path to the folder
  final String path;

  /// Display name (usually folder name)
  final String name;

  /// List of executable files found in this folder
  final List<String> discoveredApps;

  /// When the folder was last scanned
  final DateTime? lastScanned;

  const SplitTunnelFolder({
    required this.id,
    required this.path,
    required this.name,
    this.discoveredApps = const [],
    this.lastScanned,
  });

  SplitTunnelFolder copyWith({
    String? id,
    String? path,
    String? name,
    List<String>? discoveredApps,
    DateTime? lastScanned,
  }) {
    return SplitTunnelFolder(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      discoveredApps: discoveredApps ?? this.discoveredApps,
      lastScanned: lastScanned ?? this.lastScanned,
    );
  }

  factory SplitTunnelFolder.fromJson(Map<String, dynamic> json) =>
      _$SplitTunnelFolderFromJson(json);
  Map<String, dynamic> toJson() => _$SplitTunnelFolderToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitTunnelFolder &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Complete split tunneling configuration
@JsonSerializable(explicitToJson: true)
class SplitTunnelConfig {
  /// Unique identifier
  final String id;

  /// Display name for this configuration
  final String name;

  /// Whether split tunneling is enabled
  final bool enabled;

  /// Split tunneling mode (exclude or include)
  final SplitTunnelMode mode;

  /// List of excluded/included applications
  final List<AppInfo> apps;

  /// List of folders to scan for executables
  final List<SplitTunnelFolder> folders;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last modified timestamp
  final DateTime updatedAt;

  SplitTunnelConfig({
    required this.id,
    required this.name,
    this.enabled = false,
    this.mode = SplitTunnelMode.exclude,
    this.apps = const [],
    this.folders = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create a default configuration
  factory SplitTunnelConfig.defaultConfig(String id) {
    return SplitTunnelConfig(
      id: id,
      name: 'Default',
    );
  }

  SplitTunnelConfig copyWith({
    String? id,
    String? name,
    bool? enabled,
    SplitTunnelMode? mode,
    List<AppInfo>? apps,
    List<SplitTunnelFolder>? folders,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SplitTunnelConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      apps: apps ?? this.apps,
      folders: folders ?? this.folders,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Get all app IDs (from direct apps + discovered in folders)
  List<String> get allAppIds {
    final ids = <String>{};
    
    // Direct apps
    for (final app in apps) {
      ids.add(app.id);
    }
    
    // Apps discovered in folders
    for (final folder in folders) {
      ids.addAll(folder.discoveredApps);
    }
    
    return ids.toList();
  }

  /// Get total app count
  int get totalAppCount {
    int count = apps.length;
    for (final folder in folders) {
      count += folder.discoveredApps.length;
    }
    return count;
  }

  factory SplitTunnelConfig.fromJson(Map<String, dynamic> json) =>
      _$SplitTunnelConfigFromJson(json);
  Map<String, dynamic> toJson() => _$SplitTunnelConfigToJson(this);

  @override
  String toString() =>
      'SplitTunnelConfig(id: $id, enabled: $enabled, mode: $mode, apps: ${apps.length}, folders: ${folders.length})';
}
