// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'peer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Peer _$PeerFromJson(Map<String, dynamic> json) => Peer(
  id: json['id'] as String,
  publicKey: json['publicKey'] as String,
  presharedKey: json['presharedKey'] as String?,
  endpoint: json['endpoint'] as String?,
  allowedIPs:
      (json['allowedIPs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  persistentKeepalive: (json['persistentKeepalive'] as num?)?.toInt(),
);

Map<String, dynamic> _$PeerToJson(Peer instance) => <String, dynamic>{
  'id': instance.id,
  'publicKey': instance.publicKey,
  'presharedKey': instance.presharedKey,
  'endpoint': instance.endpoint,
  'allowedIPs': instance.allowedIPs,
  'persistentKeepalive': instance.persistentKeepalive,
};
