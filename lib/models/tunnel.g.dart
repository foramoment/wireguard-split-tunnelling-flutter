// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tunnel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Tunnel _$TunnelFromJson(Map<String, dynamic> json) => Tunnel(
  id: json['id'] as String,
  name: json['name'] as String,
  privateKey: json['privateKey'] as String,
  addresses:
      (json['addresses'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  dns: (json['dns'] as List<dynamic>?)?.map((e) => e as String).toList(),
  mtu: (json['mtu'] as num?)?.toInt(),
  listenPort: (json['listenPort'] as num?)?.toInt(),
  peers:
      (json['peers'] as List<dynamic>?)
          ?.map((e) => Peer.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  isActive: json['isActive'] as bool? ?? false,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  splitTunnelConfigId: json['splitTunnelConfigId'] as String?,
);

Map<String, dynamic> _$TunnelToJson(Tunnel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'privateKey': instance.privateKey,
  'addresses': instance.addresses,
  'dns': instance.dns,
  'mtu': instance.mtu,
  'listenPort': instance.listenPort,
  'peers': instance.peers.map((e) => e.toJson()).toList(),
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'splitTunnelConfigId': instance.splitTunnelConfigId,
};
