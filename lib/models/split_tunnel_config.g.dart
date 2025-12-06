// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'split_tunnel_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppInfo _$AppInfoFromJson(Map<String, dynamic> json) => AppInfo(
  id: json['id'] as String,
  name: json['name'] as String,
  path: json['path'] as String?,
  packageName: json['packageName'] as String?,
  fromFolder: json['fromFolder'] as bool? ?? false,
  folderPath: json['folderPath'] as String?,
);

Map<String, dynamic> _$AppInfoToJson(AppInfo instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'path': instance.path,
  'packageName': instance.packageName,
  'fromFolder': instance.fromFolder,
  'folderPath': instance.folderPath,
};

SplitTunnelFolder _$SplitTunnelFolderFromJson(Map<String, dynamic> json) =>
    SplitTunnelFolder(
      id: json['id'] as String,
      path: json['path'] as String,
      name: json['name'] as String,
      discoveredApps:
          (json['discoveredApps'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      lastScanned: json['lastScanned'] == null
          ? null
          : DateTime.parse(json['lastScanned'] as String),
    );

Map<String, dynamic> _$SplitTunnelFolderToJson(SplitTunnelFolder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'path': instance.path,
      'name': instance.name,
      'discoveredApps': instance.discoveredApps,
      'lastScanned': instance.lastScanned?.toIso8601String(),
    };

SplitTunnelConfig _$SplitTunnelConfigFromJson(Map<String, dynamic> json) =>
    SplitTunnelConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      enabled: json['enabled'] as bool? ?? false,
      mode:
          $enumDecodeNullable(_$SplitTunnelModeEnumMap, json['mode']) ??
          SplitTunnelMode.exclude,
      apps:
          (json['apps'] as List<dynamic>?)
              ?.map((e) => AppInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      folders:
          (json['folders'] as List<dynamic>?)
              ?.map(
                (e) => SplitTunnelFolder.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SplitTunnelConfigToJson(SplitTunnelConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'enabled': instance.enabled,
      'mode': _$SplitTunnelModeEnumMap[instance.mode]!,
      'apps': instance.apps.map((e) => e.toJson()).toList(),
      'folders': instance.folders.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$SplitTunnelModeEnumMap = {
  SplitTunnelMode.exclude: 'exclude',
  SplitTunnelMode.include: 'include',
};
