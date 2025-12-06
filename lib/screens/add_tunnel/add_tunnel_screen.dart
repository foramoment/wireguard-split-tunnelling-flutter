import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../models/tunnel.dart';
import '../../models/peer.dart';
import '../../providers/tunnel_provider.dart';
import '../../utils/config_parser.dart';
import '../../core/theme/app_colors.dart';

/// Screen for adding or editing a tunnel configuration
class AddTunnelScreen extends ConsumerStatefulWidget {
  final String? tunnelId;

  const AddTunnelScreen({super.key, this.tunnelId});

  @override
  ConsumerState<AddTunnelScreen> createState() => _AddTunnelScreenState();
}

class _AddTunnelScreenState extends ConsumerState<AddTunnelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  
  // Interface fields
  final _nameController = TextEditingController();
  final _privateKeyController = TextEditingController();
  final _addressController = TextEditingController();
  final _dnsController = TextEditingController();
  final _mtuController = TextEditingController();
  
  // Peer fields
  final _publicKeyController = TextEditingController();
  final _endpointController = TextEditingController();
  final _allowedIPsController = TextEditingController();
  final _persistentKeepaliveController = TextEditingController();
  final _presharedKeyController = TextEditingController();

  bool _isLoading = false;
  bool _isEditMode = false;
  Tunnel? _existingTunnel;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.tunnelId != null;
    if (_isEditMode) {
      _loadExistingTunnel();
    } else {
      // Set defaults
      _allowedIPsController.text = '0.0.0.0/0, ::/0';
      _persistentKeepaliveController.text = '25';
    }
  }

  Future<void> _loadExistingTunnel() async {
    setState(() => _isLoading = true);
    
    final tunnel = await ref.read(tunnelStorageServiceProvider).getTunnel(widget.tunnelId!);
    
    if (tunnel != null) {
      _existingTunnel = tunnel;
      _nameController.text = tunnel.name;
      _privateKeyController.text = tunnel.privateKey;
      _addressController.text = tunnel.addresses.join(', ');
      _dnsController.text = tunnel.dns?.join(', ') ?? '';
      _mtuController.text = tunnel.mtu?.toString() ?? '';
      
      if (tunnel.peers.isNotEmpty) {
        final peer = tunnel.peers.first;
        _publicKeyController.text = peer.publicKey;
        _endpointController.text = peer.endpoint ?? '';
        _allowedIPsController.text = peer.allowedIPs.join(', ');
        _persistentKeepaliveController.text = peer.persistentKeepalive?.toString() ?? '';
        _presharedKeyController.text = peer.presharedKey ?? '';
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _privateKeyController.dispose();
    _addressController.dispose();
    _dnsController.dispose();
    _mtuController.dispose();
    _publicKeyController.dispose();
    _endpointController.dispose();
    _allowedIPsController.dispose();
    _persistentKeepaliveController.dispose();
    _presharedKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Tunnel' : 'Create Tunnel'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Tunnel name
                  _buildTextField(
                    controller: _nameController,
                    label: 'Tunnel Name',
                    hint: 'e.g., Work VPN',
                    icon: Icons.label_outline,
                    validator: (v) => v!.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 24),

                  // Interface section
                  _buildSectionTitle(theme, 'Interface'),
                  const SizedBox(height: 8),
                  
                  _buildTextField(
                    controller: _privateKeyController,
                    label: 'Private Key',
                    hint: 'Base64 encoded private key',
                    icon: Icons.key,
                    isSecret: true,
                    validator: (v) {
                      if (v!.isEmpty) return 'Private key is required';
                      if (!WireGuardConfigParser.isValidKey(v)) {
                        return 'Invalid key format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    hint: 'e.g., 10.0.0.2/32',
                    icon: Icons.computer,
                    validator: (v) => v!.isEmpty ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _dnsController,
                    label: 'DNS (optional)',
                    hint: 'e.g., 1.1.1.1, 8.8.8.8',
                    icon: Icons.dns,
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _mtuController,
                    label: 'MTU (optional)',
                    hint: 'e.g., 1420',
                    icon: Icons.settings_ethernet,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

                  // Peer section
                  _buildSectionTitle(theme, 'Peer'),
                  const SizedBox(height: 8),

                  _buildTextField(
                    controller: _publicKeyController,
                    label: 'Public Key',
                    hint: 'Server\'s public key',
                    icon: Icons.vpn_key,
                    validator: (v) {
                      if (v!.isEmpty) return 'Public key is required';
                      if (!WireGuardConfigParser.isValidKey(v)) {
                        return 'Invalid key format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _endpointController,
                    label: 'Endpoint',
                    hint: 'e.g., vpn.example.com:51820',
                    icon: Icons.cloud,
                    validator: (v) => v!.isEmpty ? 'Endpoint is required' : null,
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _allowedIPsController,
                    label: 'Allowed IPs',
                    hint: '0.0.0.0/0, ::/0',
                    icon: Icons.security,
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _persistentKeepaliveController,
                    label: 'Persistent Keepalive (optional)',
                    hint: 'e.g., 25',
                    icon: Icons.timer,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _presharedKeyController,
                    label: 'Preshared Key (optional)',
                    hint: 'Additional security',
                    icon: Icons.enhanced_encryption,
                    isSecret: true,
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  ElevatedButton.icon(
                    onPressed: _saveTunnel,
                    icon: const Icon(Icons.save),
                    label: Text(_isEditMode ? 'Update Tunnel' : 'Create Tunnel'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isSecret = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isSecret,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }

  Future<void> _saveTunnel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Parse lists
      final addresses = _addressController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final dns = _dnsController.text.isNotEmpty
          ? _dnsController.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList()
          : null;

      final allowedIPs = _allowedIPsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Create peer
      final peer = Peer(
        id: _existingTunnel?.peers.firstOrNull?.id ?? _uuid.v4(),
        publicKey: _publicKeyController.text,
        endpoint: _endpointController.text,
        allowedIPs: allowedIPs,
        persistentKeepalive: int.tryParse(_persistentKeepaliveController.text),
        presharedKey: _presharedKeyController.text.isNotEmpty
            ? _presharedKeyController.text
            : null,
      );

      // Create tunnel
      final tunnel = Tunnel(
        id: _existingTunnel?.id ?? _uuid.v4(),
        name: _nameController.text,
        privateKey: _privateKeyController.text,
        addresses: addresses,
        dns: dns,
        mtu: int.tryParse(_mtuController.text),
        peers: [peer],
        createdAt: _existingTunnel?.createdAt,
      );

      // Save
      if (_isEditMode) {
        await ref.read(tunnelsProvider.notifier).updateTunnel(tunnel);
      } else {
        await ref.read(tunnelsProvider.notifier).addTunnel(tunnel);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Tunnel updated' : 'Tunnel created'),
            backgroundColor: AppColors.connected,
          ),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
