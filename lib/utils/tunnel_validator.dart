/// Comprehensive WireGuard tunnel configuration validator
///
/// Provides validation for all WireGuard configuration fields with
/// user-friendly error messages.
class TunnelValidator {
  // WireGuard keys are 32 bytes base64 encoded = 44 characters
  static const int _keyLength = 44;
  
  // Valid MTU range for WireGuard
  static const int _minMtu = 1280;
  static const int _maxMtu = 1500;
  
  // Valid port range
  static const int _minPort = 1;
  static const int _maxPort = 65535;
  
  // Valid keepalive range (0 = disabled)
  static const int _maxKeepalive = 65535;

  /// Validate a WireGuard private or public key
  /// 
  /// Keys are 32-byte Curve25519 keys, base64-encoded (44 chars with padding)
  static String? validateKey(String? value, {bool required = true, String fieldName = 'Key'}) {
    if (value == null || value.isEmpty) {
      return required ? '$fieldName is required' : null;
    }
    
    value = value.trim();
    
    if (value.length != _keyLength) {
      return '$fieldName must be $_keyLength characters (got ${value.length})';
    }
    
    // Must end with = (base64 padding for 32 bytes)
    if (!value.endsWith('=')) {
      return '$fieldName must end with = (base64 padding)';
    }
    
    // Check base64 characters (standard base64 alphabet)
    if (!RegExp(r'^[A-Za-z0-9+/]{43}=$').hasMatch(value)) {
      return '$fieldName contains invalid characters';
    }
    
    return null;
  }

  /// Validate a private key (same format as public key for WireGuard)
  static String? validatePrivateKey(String? value) {
    return validateKey(value, required: true, fieldName: 'Private key');
  }

  /// Validate a public key
  static String? validatePublicKey(String? value) {
    return validateKey(value, required: true, fieldName: 'Public key');
  }

  /// Validate a preshared key (optional, but if provided must be valid)
  static String? validatePresharedKey(String? value) {
    return validateKey(value, required: false, fieldName: 'Preshared key');
  }

  /// Validate an IPv4 address
  static bool _isValidIPv4(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
      // Check for leading zeros (e.g., "01" is invalid)
      if (part.length > 1 && part.startsWith('0')) return false;
    }
    
    return true;
  }

  /// Validate an IPv6 address
  static bool _isValidIPv6(String ip) {
    // Handle :: shorthand
    if (ip == '::') return true;
    
    // Count colons and check for valid hex groups
    final parts = ip.split(':');
    
    // Check for empty string handling (from ::)
    int emptyCount = parts.where((p) => p.isEmpty).length;
    
    // :: can appear at most once
    if (emptyCount > 2) return false;
    
    // If :: is used, we can have fewer than 8 groups
    final hasDoubleColon = ip.contains('::');
    if (!hasDoubleColon && parts.length != 8) return false;
    if (hasDoubleColon && parts.length > 8) return false;
    
    // Validate each part is valid hex (1-4 chars)
    for (final part in parts) {
      if (part.isEmpty) continue; // Part of ::
      if (part.length > 4) return false;
      if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(part)) return false;
    }
    
    return true;
  }

  /// Validate an IP address with CIDR notation (e.g., "10.0.0.2/32")
  static String? validateAddressWithCidr(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'Address is required' : null;
    }
    
    value = value.trim();
    
    final parts = value.split('/');
    if (parts.length != 2) {
      return 'Address must include CIDR notation (e.g., /32)';
    }
    
    final ip = parts[0];
    final cidrStr = parts[1];
    final cidr = int.tryParse(cidrStr);
    
    if (cidr == null) {
      return 'Invalid CIDR notation';
    }
    
    // IPv4
    if (ip.contains('.')) {
      if (!_isValidIPv4(ip)) {
        return 'Invalid IPv4 address format';
      }
      if (cidr < 0 || cidr > 32) {
        return 'IPv4 CIDR must be 0-32 (got $cidr)';
      }
      return null;
    }
    
    // IPv6
    if (ip.contains(':')) {
      if (!_isValidIPv6(ip)) {
        return 'Invalid IPv6 address format';
      }
      if (cidr < 0 || cidr > 128) {
        return 'IPv6 CIDR must be 0-128 (got $cidr)';
      }
      return null;
    }
    
    return 'Invalid IP address format';
  }

  /// Validate a list of addresses (comma-separated)
  static String? validateAddressList(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'At least one address is required' : null;
    }
    
    final addresses = value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    
    if (addresses.isEmpty) {
      return required ? 'At least one address is required' : null;
    }
    
    for (final address in addresses) {
      final error = validateAddressWithCidr(address);
      if (error != null) {
        return 'Invalid address "$address": $error';
      }
    }
    
    return null;
  }

  /// Validate an endpoint (host:port format)
  static String? validateEndpoint(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'Endpoint is required' : null;
    }
    
    value = value.trim();
    
    // Handle IPv6 endpoints like [::1]:51820
    if (value.startsWith('[')) {
      final closeBracket = value.indexOf(']');
      if (closeBracket == -1) {
        return 'IPv6 endpoint must be in [address]:port format';
      }
      
      final ipv6 = value.substring(1, closeBracket);
      if (!_isValidIPv6(ipv6)) {
        return 'Invalid IPv6 address in endpoint';
      }
      
      final rest = value.substring(closeBracket + 1);
      if (!rest.startsWith(':') || rest.length < 2) {
        return 'Endpoint must include port (e.g., [::1]:51820)';
      }
      
      final port = int.tryParse(rest.substring(1));
      if (port == null || port < _minPort || port > _maxPort) {
        return 'Port must be $_minPort-$_maxPort';
      }
      
      return null;
    }
    
    // Standard host:port format
    final parts = value.split(':');
    if (parts.length != 2) {
      return 'Endpoint must be in host:port format';
    }
    
    final host = parts[0];
    final portStr = parts[1];
    
    if (host.isEmpty) {
      return 'Host cannot be empty';
    }
    
    // Validate host (domain or IPv4)
    if (!_isValidHostname(host) && !_isValidIPv4(host)) {
      return 'Invalid hostname or IP address';
    }
    
    final port = int.tryParse(portStr);
    if (port == null || port < _minPort || port > _maxPort) {
      return 'Port must be $_minPort-$_maxPort';
    }
    
    return null;
  }

  /// Validate a hostname
  static bool _isValidHostname(String hostname) {
    if (hostname.isEmpty || hostname.length > 253) return false;
    
    // Each label must be 1-63 chars, alphanumeric or hyphen (not start/end with hyphen)
    final labels = hostname.split('.');
    for (final label in labels) {
      if (label.isEmpty || label.length > 63) return false;
      if (label.startsWith('-') || label.endsWith('-')) return false;
      if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(label)) return false;
    }
    
    return true;
  }

  /// Validate DNS servers (comma-separated IP addresses)
  static String? validateDns(String? value) {
    if (value == null || value.isEmpty) {
      return null; // DNS is optional
    }
    
    final servers = value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    
    for (final server in servers) {
      if (!_isValidIPv4(server) && !_isValidIPv6(server)) {
        return 'Invalid DNS server: $server';
      }
    }
    
    return null;
  }

  /// Validate MTU value
  static String? validateMtu(String? value) {
    if (value == null || value.isEmpty) {
      return null; // MTU is optional
    }
    
    final mtu = int.tryParse(value);
    if (mtu == null) {
      return 'MTU must be a number';
    }
    
    if (mtu < _minMtu || mtu > _maxMtu) {
      return 'MTU must be $_minMtu-$_maxMtu (got $mtu)';
    }
    
    return null;
  }

  /// Validate Persistent Keepalive value
  static String? validatePersistentKeepalive(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Keepalive is optional
    }
    
    final keepalive = int.tryParse(value);
    if (keepalive == null) {
      return 'Keepalive must be a number';
    }
    
    if (keepalive < 0 || keepalive > _maxKeepalive) {
      return 'Keepalive must be 0-$_maxKeepalive seconds';
    }
    
    return null;
  }

  /// Validate Allowed IPs (comma-separated CIDR addresses)
  static String? validateAllowedIPs(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'Allowed IPs is required' : null;
    }
    
    final ips = value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    
    if (required && ips.isEmpty) {
      return 'At least one allowed IP is required';
    }
    
    for (final ip in ips) {
      final error = validateAddressWithCidr(ip, required: true);
      if (error != null) {
        return 'Invalid allowed IP "$ip": $error';
      }
    }
    
    return null;
  }

  /// Validate tunnel name
  static String? validateTunnelName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tunnel name is required';
    }
    
    if (value.length > 50) {
      return 'Name must be 50 characters or less';
    }
    
    // Check for invalid characters (keeping it simple - alphanumeric, space, dash, underscore)
    if (!RegExp(r'^[a-zA-Z0-9\s\-_]+$').hasMatch(value)) {
      return 'Name can only contain letters, numbers, spaces, dashes, and underscores';
    }
    
    return null;
  }

  /// Validate listen port
  static String? validateListenPort(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Listen port is optional
    }
    
    final port = int.tryParse(value);
    if (port == null) {
      return 'Listen port must be a number';
    }
    
    if (port < _minPort || port > _maxPort) {
      return 'Port must be $_minPort-$_maxPort';
    }
    
    return null;
  }

  /// Validate an entire tunnel configuration
  /// Returns a map of field -> error message, or empty map if all valid
  static Map<String, String> validateTunnelConfig({
    required String name,
    required String privateKey,
    required String addresses,
    String? dns,
    String? mtu,
    String? listenPort,
    required String publicKey,
    required String endpoint,
    String? allowedIPs,
    String? persistentKeepalive,
    String? presharedKey,
  }) {
    final errors = <String, String>{};
    
    final nameError = validateTunnelName(name);
    if (nameError != null) errors['name'] = nameError;
    
    final privateKeyError = validatePrivateKey(privateKey);
    if (privateKeyError != null) errors['privateKey'] = privateKeyError;
    
    final addressError = validateAddressList(addresses);
    if (addressError != null) errors['addresses'] = addressError;
    
    final dnsError = validateDns(dns);
    if (dnsError != null) errors['dns'] = dnsError;
    
    final mtuError = validateMtu(mtu);
    if (mtuError != null) errors['mtu'] = mtuError;
    
    final listenPortError = validateListenPort(listenPort);
    if (listenPortError != null) errors['listenPort'] = listenPortError;
    
    final publicKeyError = validatePublicKey(publicKey);
    if (publicKeyError != null) errors['publicKey'] = publicKeyError;
    
    final endpointError = validateEndpoint(endpoint);
    if (endpointError != null) errors['endpoint'] = endpointError;
    
    final allowedIPsError = validateAllowedIPs(allowedIPs);
    if (allowedIPsError != null) errors['allowedIPs'] = allowedIPsError;
    
    final keepaliveError = validatePersistentKeepalive(persistentKeepalive);
    if (keepaliveError != null) errors['persistentKeepalive'] = keepaliveError;
    
    final presharedKeyError = validatePresharedKey(presharedKey);
    if (presharedKeyError != null) errors['presharedKey'] = presharedKeyError;
    
    return errors;
  }
}
