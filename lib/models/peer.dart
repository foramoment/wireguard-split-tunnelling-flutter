import 'package:json_annotation/json_annotation.dart';

part 'peer.g.dart';

/// Represents a WireGuard peer configuration
@JsonSerializable()
class Peer {
  /// Unique identifier for this peer
  final String id;

  /// Public key of the peer (required)
  final String publicKey;

  /// Pre-shared key for additional security (optional)
  final String? presharedKey;

  /// Endpoint address (e.g., "vpn.example.com:51820")
  final String? endpoint;

  /// Allowed IPs for this peer (e.g., ["0.0.0.0/0", "::/0"])
  final List<String> allowedIPs;

  /// Persistent keepalive interval in seconds (0 = disabled)
  final int? persistentKeepalive;

  /// Last handshake timestamp (populated at runtime)
  @JsonKey(includeFromJson: false, includeToJson: false)
  DateTime? lastHandshake;

  /// Bytes received from this peer (populated at runtime)
  @JsonKey(includeFromJson: false, includeToJson: false)
  int? rxBytes;

  /// Bytes sent to this peer (populated at runtime)
  @JsonKey(includeFromJson: false, includeToJson: false)
  int? txBytes;

  Peer({
    required this.id,
    required this.publicKey,
    this.presharedKey,
    this.endpoint,
    this.allowedIPs = const [],
    this.persistentKeepalive,
    this.lastHandshake,
    this.rxBytes,
    this.txBytes,
  });

  /// Create a copy with modified fields
  Peer copyWith({
    String? id,
    String? publicKey,
    String? presharedKey,
    String? endpoint,
    List<String>? allowedIPs,
    int? persistentKeepalive,
    DateTime? lastHandshake,
    int? rxBytes,
    int? txBytes,
  }) {
    return Peer(
      id: id ?? this.id,
      publicKey: publicKey ?? this.publicKey,
      presharedKey: presharedKey ?? this.presharedKey,
      endpoint: endpoint ?? this.endpoint,
      allowedIPs: allowedIPs ?? this.allowedIPs,
      persistentKeepalive: persistentKeepalive ?? this.persistentKeepalive,
      lastHandshake: lastHandshake ?? this.lastHandshake,
      rxBytes: rxBytes ?? this.rxBytes,
      txBytes: txBytes ?? this.txBytes,
    );
  }

  factory Peer.fromJson(Map<String, dynamic> json) => _$PeerFromJson(json);
  Map<String, dynamic> toJson() => _$PeerToJson(this);

  /// Generate WireGuard config section for this peer
  String toConfigString() {
    final buffer = StringBuffer();
    buffer.writeln('[Peer]');
    buffer.writeln('PublicKey = $publicKey');
    
    if (presharedKey != null && presharedKey!.isNotEmpty) {
      buffer.writeln('PresharedKey = $presharedKey');
    }
    
    if (allowedIPs.isNotEmpty) {
      buffer.writeln('AllowedIPs = ${allowedIPs.join(', ')}');
    }
    
    if (endpoint != null && endpoint!.isNotEmpty) {
      buffer.writeln('Endpoint = $endpoint');
    }
    
    if (persistentKeepalive != null && persistentKeepalive! > 0) {
      buffer.writeln('PersistentKeepalive = $persistentKeepalive');
    }
    
    return buffer.toString();
  }

  @override
  String toString() => 'Peer(publicKey: ${publicKey.substring(0, 8)}..., endpoint: $endpoint)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Peer &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          publicKey == other.publicKey;

  @override
  int get hashCode => id.hashCode ^ publicKey.hashCode;
}
