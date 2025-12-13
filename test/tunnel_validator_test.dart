import 'package:flutter_test/flutter_test.dart';
import 'package:wg_client/utils/tunnel_validator.dart';

void main() {
  group('TunnelValidator', () {
    group('validateKey', () {
      test('should accept valid WireGuard key', () {
        // Valid 44-char base64 key ending with =
        const validKey = 'cK7tT6/rlHBRxq8cXtVCqKdfKy1xFVKIBl0kB7wz/Xo=';
        expect(TunnelValidator.validatePrivateKey(validKey), isNull);
        expect(TunnelValidator.validatePublicKey(validKey), isNull);
      });

      test('should reject key that is too short', () {
        const shortKey = 'cK7tT6/rlHBRxq8cXtVCqKdfKy1xFVKI';
        final error = TunnelValidator.validatePrivateKey(shortKey);
        expect(error, contains('44 characters'));
      });

      test('should reject key that is too long', () {
        const longKey = 'cK7tT6/rlHBRxq8cXtVCqKdfKy1xFVKIBl0kB7wz/Xo==';
        final error = TunnelValidator.validatePrivateKey(longKey);
        expect(error, isNotNull);
      });

      test('should reject key without base64 padding', () {
        const noPaddingKey = 'cK7tT6/rlHBRxq8cXtVCqKdfKy1xFVKIBl0kB7wz/XoX';
        final error = TunnelValidator.validatePrivateKey(noPaddingKey);
        expect(error, contains('='));
      });

      test('should reject empty key when required', () {
        final error = TunnelValidator.validatePrivateKey('');
        expect(error, contains('required'));
      });

      test('should accept empty preshared key (optional)', () {
        expect(TunnelValidator.validatePresharedKey(''), isNull);
        expect(TunnelValidator.validatePresharedKey(null), isNull);
      });

      test('should reject key with invalid characters', () {
        const invalidKey = 'cK7tT6/rlHBRxq8cXtVCq!dfKy1xFVKIBl0kB7wz/Xo=';
        final error = TunnelValidator.validatePrivateKey(invalidKey);
        expect(error, contains('invalid characters'));
      });
    });

    group('validateAddressWithCidr', () {
      test('should accept valid IPv4 with CIDR', () {
        expect(TunnelValidator.validateAddressWithCidr('10.0.0.2/32'), isNull);
        expect(TunnelValidator.validateAddressWithCidr('192.168.1.1/24'), isNull);
        expect(TunnelValidator.validateAddressWithCidr('0.0.0.0/0'), isNull);
      });

      test('should accept valid IPv6 with CIDR', () {
        expect(TunnelValidator.validateAddressWithCidr('fd00::2/128'), isNull);
        expect(TunnelValidator.validateAddressWithCidr('::/0'), isNull);
        expect(TunnelValidator.validateAddressWithCidr('2001:db8::1/64'), isNull);
      });

      test('should reject IPv4 without CIDR', () {
        final error = TunnelValidator.validateAddressWithCidr('10.0.0.2');
        expect(error, contains('CIDR'));
      });

      test('should reject IPv4 with invalid CIDR range', () {
        final error = TunnelValidator.validateAddressWithCidr('10.0.0.2/33');
        expect(error, contains('0-32'));
      });

      test('should reject IPv6 with invalid CIDR range', () {
        final error = TunnelValidator.validateAddressWithCidr('fd00::2/129');
        expect(error, contains('0-128'));
      });

      test('should reject invalid IPv4 octet', () {
        final error = TunnelValidator.validateAddressWithCidr('10.0.0.256/32');
        expect(error, contains('Invalid IPv4'));
      });
    });

    group('validateAddressList', () {
      test('should accept single address', () {
        expect(TunnelValidator.validateAddressList('10.0.0.2/32'), isNull);
      });

      test('should accept comma-separated addresses', () {
        expect(TunnelValidator.validateAddressList('10.0.0.2/32, fd00::2/128'), isNull);
      });

      test('should reject if any address is invalid', () {
        final error = TunnelValidator.validateAddressList('10.0.0.2/32, invalid');
        expect(error, contains('Invalid'));
      });

      test('should reject empty when required', () {
        final error = TunnelValidator.validateAddressList('');
        expect(error, contains('required'));
      });
    });

    group('validateEndpoint', () {
      test('should accept valid hostname:port', () {
        expect(TunnelValidator.validateEndpoint('vpn.example.com:51820'), isNull);
        expect(TunnelValidator.validateEndpoint('my-server.io:1234'), isNull);
      });

      test('should accept valid IPv4:port', () {
        expect(TunnelValidator.validateEndpoint('192.168.1.1:51820'), isNull);
        expect(TunnelValidator.validateEndpoint('1.2.3.4:65535'), isNull);
      });

      test('should accept valid IPv6 endpoint', () {
        expect(TunnelValidator.validateEndpoint('[::1]:51820'), isNull);
        expect(TunnelValidator.validateEndpoint('[2001:db8::1]:51820'), isNull);
      });

      test('should reject invalid port', () {
        expect(TunnelValidator.validateEndpoint('vpn.example.com:0'), contains('1-65535'));
        expect(TunnelValidator.validateEndpoint('vpn.example.com:65536'), contains('1-65535'));
        expect(TunnelValidator.validateEndpoint('vpn.example.com:abc'), contains('1-65535'));
      });

      test('should reject missing port', () {
        final error = TunnelValidator.validateEndpoint('vpn.example.com');
        expect(error, contains('host:port'));
      });

      test('should reject empty endpoint when required', () {
        final error = TunnelValidator.validateEndpoint('');
        expect(error, contains('required'));
      });
    });

    group('validateDns', () {
      test('should accept empty DNS (optional)', () {
        expect(TunnelValidator.validateDns(''), isNull);
        expect(TunnelValidator.validateDns(null), isNull);
      });

      test('should accept valid DNS servers', () {
        expect(TunnelValidator.validateDns('1.1.1.1'), isNull);
        expect(TunnelValidator.validateDns('8.8.8.8, 8.8.4.4'), isNull);
        expect(TunnelValidator.validateDns('2606:4700:4700::1111'), isNull);
      });

      test('should reject invalid DNS server', () {
        final error = TunnelValidator.validateDns('not-an-ip');
        expect(error, contains('Invalid DNS'));
      });
    });

    group('validateMtu', () {
      test('should accept empty MTU (optional)', () {
        expect(TunnelValidator.validateMtu(''), isNull);
        expect(TunnelValidator.validateMtu(null), isNull);
      });

      test('should accept valid MTU values', () {
        expect(TunnelValidator.validateMtu('1280'), isNull);
        expect(TunnelValidator.validateMtu('1420'), isNull);
        expect(TunnelValidator.validateMtu('1500'), isNull);
      });

      test('should reject MTU outside valid range', () {
        expect(TunnelValidator.validateMtu('1279'), contains('1280-1500'));
        expect(TunnelValidator.validateMtu('1501'), contains('1280-1500'));
      });

      test('should reject non-numeric MTU', () {
        expect(TunnelValidator.validateMtu('abc'), contains('number'));
      });
    });

    group('validatePersistentKeepalive', () {
      test('should accept empty keepalive (optional)', () {
        expect(TunnelValidator.validatePersistentKeepalive(''), isNull);
        expect(TunnelValidator.validatePersistentKeepalive(null), isNull);
      });

      test('should accept valid keepalive values', () {
        expect(TunnelValidator.validatePersistentKeepalive('0'), isNull);
        expect(TunnelValidator.validatePersistentKeepalive('25'), isNull);
        expect(TunnelValidator.validatePersistentKeepalive('65535'), isNull);
      });

      test('should reject negative keepalive', () {
        expect(TunnelValidator.validatePersistentKeepalive('-1'), contains('0-65535'));
      });
    });

    group('validateAllowedIPs', () {
      test('should accept empty allowed IPs (optional by default)', () {
        expect(TunnelValidator.validateAllowedIPs(''), isNull);
        expect(TunnelValidator.validateAllowedIPs(null), isNull);
      });

      test('should accept valid allowed IPs', () {
        expect(TunnelValidator.validateAllowedIPs('0.0.0.0/0'), isNull);
        expect(TunnelValidator.validateAllowedIPs('0.0.0.0/0, ::/0'), isNull);
        expect(TunnelValidator.validateAllowedIPs('10.0.0.0/8, 192.168.0.0/16'), isNull);
      });

      test('should reject invalid allowed IPs', () {
        final error = TunnelValidator.validateAllowedIPs('invalid');
        expect(error, contains('Invalid'));
      });
    });

    group('validateTunnelName', () {
      test('should accept valid tunnel names', () {
        expect(TunnelValidator.validateTunnelName('Work VPN'), isNull);
        expect(TunnelValidator.validateTunnelName('my-tunnel-1'), isNull);
        expect(TunnelValidator.validateTunnelName('tunnel_test'), isNull);
      });

      test('should reject empty name', () {
        final error = TunnelValidator.validateTunnelName('');
        expect(error, contains('required'));
      });

      test('should reject name with special characters', () {
        final error = TunnelValidator.validateTunnelName('tunnel@home');
        expect(error, contains('letters, numbers'));
      });

      test('should reject name that is too long', () {
        final longName = 'a' * 51;
        final error = TunnelValidator.validateTunnelName(longName);
        expect(error, contains('50 characters'));
      });
    });

    group('validateTunnelConfig', () {
      test('should return empty map for valid config', () {
        final errors = TunnelValidator.validateTunnelConfig(
          name: 'Test Tunnel',
          privateKey: 'cK7tT6/rlHBRxq8cXtVCqKdfKy1xFVKIBl0kB7wz/Xo=',
          addresses: '10.0.0.2/32',
          dns: '1.1.1.1',
          mtu: '1420',
          publicKey: 'cK7tT6/rlHBRxq8cXtVCqKdfKy1xFVKIBl0kB7wz/Xo=',
          endpoint: 'vpn.example.com:51820',
          allowedIPs: '0.0.0.0/0',
          persistentKeepalive: '25',
        );
        expect(errors, isEmpty);
      });

      test('should return errors for invalid fields', () {
        final errors = TunnelValidator.validateTunnelConfig(
          name: '',
          privateKey: 'invalid',
          addresses: 'invalid',
          publicKey: 'invalid',
          endpoint: 'no-port',
        );
        expect(errors.containsKey('name'), isTrue);
        expect(errors.containsKey('privateKey'), isTrue);
        expect(errors.containsKey('addresses'), isTrue);
        expect(errors.containsKey('publicKey'), isTrue);
        expect(errors.containsKey('endpoint'), isTrue);
      });
    });
  });
}
