import 'package:uuid/uuid.dart';
import '../models/tunnel.dart';
import '../models/peer.dart';

/// Parser for WireGuard configuration files
class WireGuardConfigParser {
  static const _uuid = Uuid();

  /// Parse a WireGuard .conf file content into a Tunnel object
  /// 
  /// Throws [FormatException] if the config is invalid
  static Tunnel parse(String configContent, {String? name}) {
    final lines = configContent.split('\n');
    
    String? privateKey;
    List<String> addresses = [];
    List<String>? dns;
    int? mtu;
    int? listenPort;
    List<Peer> peers = [];
    
    // Current section being parsed
    String? currentSection;
    
    // Peer building variables
    String? peerPublicKey;
    String? peerPresharedKey;
    String? peerEndpoint;
    List<String> peerAllowedIPs = [];
    int? peerPersistentKeepalive;
    
    void savePeerIfExists() {
      if (peerPublicKey != null) {
        peers.add(Peer(
          id: _uuid.v4(),
          publicKey: peerPublicKey!,
          presharedKey: peerPresharedKey,
          endpoint: peerEndpoint,
          allowedIPs: List.from(peerAllowedIPs),
          persistentKeepalive: peerPersistentKeepalive,
        ));
        
        // Reset peer variables
        peerPublicKey = null;
        peerPresharedKey = null;
        peerEndpoint = null;
        peerAllowedIPs = [];
        peerPersistentKeepalive = null;
      }
    }
    
    for (var line in lines) {
      line = line.trim();
      
      // Skip empty lines and comments
      if (line.isEmpty || line.startsWith('#')) continue;
      
      // Check for section headers
      if (line.toLowerCase() == '[interface]') {
        savePeerIfExists();
        currentSection = 'interface';
        continue;
      }
      
      if (line.toLowerCase() == '[peer]') {
        savePeerIfExists();
        currentSection = 'peer';
        continue;
      }
      
      // Parse key = value pairs
      final parts = line.split('=');
      if (parts.length < 2) continue;
      
      final key = parts[0].trim().toLowerCase();
      final value = parts.sublist(1).join('=').trim();
      
      if (currentSection == 'interface') {
        switch (key) {
          case 'privatekey':
            privateKey = value;
            break;
          case 'address':
            addresses = _parseList(value);
            break;
          case 'dns':
            dns = _parseList(value);
            break;
          case 'mtu':
            mtu = int.tryParse(value);
            break;
          case 'listenport':
            listenPort = int.tryParse(value);
            break;
        }
      } else if (currentSection == 'peer') {
        switch (key) {
          case 'publickey':
            peerPublicKey = value;
            break;
          case 'presharedkey':
            peerPresharedKey = value;
            break;
          case 'endpoint':
            peerEndpoint = value;
            break;
          case 'allowedips':
            peerAllowedIPs = _parseList(value);
            break;
          case 'persistentkeepalive':
            peerPersistentKeepalive = int.tryParse(value);
            break;
        }
      }
    }
    
    // Don't forget the last peer
    savePeerIfExists();
    
    // Validate required fields
    if (privateKey == null || privateKey.isEmpty) {
      throw FormatException('Missing required PrivateKey in [Interface] section');
    }
    
    if (addresses.isEmpty) {
      throw FormatException('Missing required Address in [Interface] section');
    }
    
    if (peers.isEmpty) {
      throw FormatException('At least one [Peer] section is required');
    }
    
    // Generate tunnel name from filename or endpoint
    final tunnelName = name ?? 
        _extractNameFromEndpoint(peers.first.endpoint) ?? 
        'Tunnel ${DateTime.now().millisecondsSinceEpoch}';
    
    return Tunnel(
      id: _uuid.v4(),
      name: tunnelName,
      privateKey: privateKey,
      addresses: addresses,
      dns: dns,
      mtu: mtu,
      listenPort: listenPort,
      peers: peers,
    );
  }
  
  /// Parse a comma or whitespace separated list
  static List<String> _parseList(String value) {
    return value
        .split(RegExp(r'[,\s]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  
  /// Extract a reasonable name from endpoint
  static String? _extractNameFromEndpoint(String? endpoint) {
    if (endpoint == null || endpoint.isEmpty) return null;
    
    // Remove port
    final parts = endpoint.split(':');
    final host = parts.first;
    
    // If it's an IP, return null
    if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(host)) {
      return null;
    }
    
    // Return domain without common prefixes/suffixes
    return host
        .replaceAll(RegExp(r'^(vpn|wg|wireguard)\.'), '')
        .replaceAll(RegExp(r'\.(com|net|org|io)$'), '')
        .split('.')
        .first;
  }

  /// Validate if a string is a valid WireGuard config
  static bool isValidConfig(String content) {
    try {
      parse(content);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Validate a WireGuard private/public key format (base64, 44 chars)
  static bool isValidKey(String key) {
    if (key.length != 44) return false;
    
    // Must end with = (base64 padding)
    if (!key.endsWith('=')) return false;
    
    // Check base64 characters
    return RegExp(r'^[A-Za-z0-9+/]{43}=$').hasMatch(key);
  }

  /// Validate an IP address with CIDR notation
  static bool isValidAddressWithCidr(String address) {
    final parts = address.split('/');
    if (parts.length != 2) return false;
    
    final ip = parts[0];
    final cidr = int.tryParse(parts[1]);
    
    if (cidr == null) return false;
    
    // IPv4
    if (ip.contains('.')) {
      if (cidr < 0 || cidr > 32) return false;
      return RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(ip);
    }
    
    // IPv6
    if (ip.contains(':')) {
      if (cidr < 0 || cidr > 128) return false;
      return true; // Simple check, could be more thorough
    }
    
    return false;
  }

  /// Validate an endpoint format (host:port)
  static bool isValidEndpoint(String endpoint) {
    final parts = endpoint.split(':');
    if (parts.length != 2) return false;
    
    final port = int.tryParse(parts[1]);
    if (port == null || port < 1 || port > 65535) return false;
    
    return parts[0].isNotEmpty;
  }
}
