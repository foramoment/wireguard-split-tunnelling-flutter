import 'package:json_annotation/json_annotation.dart';
import 'peer.dart';

part 'tunnel.g.dart';

/// Represents a complete WireGuard tunnel configuration
@JsonSerializable(explicitToJson: true)
class Tunnel {
  /// Unique identifier for this tunnel
  final String id;

  /// Display name for the tunnel
  final String name;

  /// Interface private key (required)
  final String privateKey;

  /// Interface addresses (e.g., ["10.0.0.2/32", "fd00::2/128"])
  final List<String> addresses;

  /// DNS servers (optional)
  final List<String>? dns;

  /// MTU setting (optional, typically 1280-1500)
  final int? mtu;

  /// Listen port for the interface (optional)
  final int? listenPort;

  /// List of peers for this tunnel
  final List<Peer> peers;

  /// Whether this tunnel is the default/active one
  final bool isActive;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last modified timestamp
  final DateTime updatedAt;

  /// Split tunneling configuration ID (if enabled)
  final String? splitTunnelConfigId;

  Tunnel({
    required this.id,
    required this.name,
    required this.privateKey,
    this.addresses = const [],
    this.dns,
    this.mtu,
    this.listenPort,
    this.peers = const [],
    this.isActive = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.splitTunnelConfigId,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create a copy with modified fields
  Tunnel copyWith({
    String? id,
    String? name,
    String? privateKey,
    List<String>? addresses,
    List<String>? dns,
    int? mtu,
    int? listenPort,
    List<Peer>? peers,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? splitTunnelConfigId,
  }) {
    return Tunnel(
      id: id ?? this.id,
      name: name ?? this.name,
      privateKey: privateKey ?? this.privateKey,
      addresses: addresses ?? this.addresses,
      dns: dns ?? this.dns,
      mtu: mtu ?? this.mtu,
      listenPort: listenPort ?? this.listenPort,
      peers: peers ?? this.peers,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      splitTunnelConfigId: splitTunnelConfigId ?? this.splitTunnelConfigId,
    );
  }

  factory Tunnel.fromJson(Map<String, dynamic> json) => _$TunnelFromJson(json);
  Map<String, dynamic> toJson() => _$TunnelToJson(this);

  /// Generate full WireGuard configuration file content
  String toConfigString() {
    final buffer = StringBuffer();
    
    // [Interface] section
    buffer.writeln('[Interface]');
    buffer.writeln('PrivateKey = $privateKey');
    
    if (addresses.isNotEmpty) {
      buffer.writeln('Address = ${addresses.join(', ')}');
    }
    
    if (dns != null && dns!.isNotEmpty) {
      buffer.writeln('DNS = ${dns!.join(', ')}');
    }
    
    if (mtu != null) {
      buffer.writeln('MTU = $mtu');
    }
    
    if (listenPort != null) {
      buffer.writeln('ListenPort = $listenPort');
    }
    
    // [Peer] sections
    for (final peer in peers) {
      buffer.writeln();
      buffer.write(peer.toConfigString());
    }
    
    return buffer.toString();
  }

  /// Get the primary address (first in list)
  String? get primaryAddress => addresses.isNotEmpty ? addresses.first : null;

  /// Get the primary endpoint from first peer
  String? get primaryEndpoint => peers.isNotEmpty ? peers.first.endpoint : null;

  /// Check if tunnel has valid configuration
  bool get isValid =>
      privateKey.isNotEmpty &&
      addresses.isNotEmpty &&
      peers.isNotEmpty &&
      peers.every((p) => p.publicKey.isNotEmpty);

  @override
  String toString() => 'Tunnel(id: $id, name: $name, peers: ${peers.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tunnel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
