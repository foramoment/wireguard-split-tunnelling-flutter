import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/tunnel.dart';
import '../../models/connection_status.dart';
import '../../providers/tunnel_provider.dart';
import '../../providers/vpn_connection_provider.dart';
import '../../core/theme/app_colors.dart';

/// Tunnel details screen showing full configuration and stats
class TunnelDetailsScreen extends ConsumerWidget {
  final String tunnelId;

  const TunnelDetailsScreen({
    super.key,
    required this.tunnelId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tunnelAsync = ref.watch(tunnelProvider(tunnelId));
    final connectionStatus = ref.watch(vpnConnectionProvider);

    return tunnelAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $error')),
      ),
      data: (tunnel) {
        if (tunnel == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(child: Text('Tunnel not found')),
          );
        }

        final isConnected =
            connectionStatus.isConnected && connectionStatus.tunnelId == tunnelId;
        final isConnecting =
            connectionStatus.isConnecting && connectionStatus.tunnelId == tunnelId;

        return Scaffold(
          appBar: AppBar(
            title: Text(tunnel.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: () => context.push('/tunnel/$tunnelId/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () => _showDeleteDialog(context, ref, tunnel),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Connection status card
              _buildStatusCard(context, tunnel, isConnected, isConnecting, ref),
              const SizedBox(height: 16),

              // Interface section
              _buildSectionTitle(context, 'Interface'),
              _buildCard(context, [
                _buildInfoRow(context, 'Address', tunnel.addresses.join(', ')),
                if (tunnel.dns != null && tunnel.dns!.isNotEmpty)
                  _buildInfoRow(context, 'DNS', tunnel.dns!.join(', ')),
                if (tunnel.mtu != null)
                  _buildInfoRow(context, 'MTU', tunnel.mtu.toString()),
                if (tunnel.listenPort != null)
                  _buildInfoRow(context, 'Listen Port', tunnel.listenPort.toString()),
                _buildKeyRow(context, 'Private Key', tunnel.privateKey),
              ]),
              const SizedBox(height: 16),

              // Peers section
              _buildSectionTitle(context, 'Peers (${tunnel.peers.length})'),
              ...tunnel.peers.map((peer) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildPeerCard(context, peer),
              )),

              const SizedBox(height: 16),

              // Split tunneling link
              _buildSplitTunnelingCard(context, tunnel),

              const SizedBox(height: 16),

              // Export button
              OutlinedButton.icon(
                onPressed: () => _exportConfig(context, tunnel),
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Export Configuration'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    Tunnel tunnel,
    bool isConnected,
    bool isConnecting,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final connectionStatus = ref.watch(vpnConnectionProvider);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isConnected) {
      statusColor = AppColors.connected;
      statusIcon = Icons.shield;
      statusText = 'Connected';
    } else if (isConnecting) {
      statusColor = AppColors.connecting;
      statusIcon = Icons.sync;
      statusText = 'Connecting...';
    } else {
      statusColor = AppColors.disconnected;
      statusIcon = Icons.shield_outlined;
      statusText = 'Disconnected';
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: isConnected
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.connected.withAlpha(isDark ? 40 : 25),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : null,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status icon and text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(isDark ? 40 : 25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: isConnecting
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation(statusColor),
                          ),
                        )
                      : Icon(statusIcon, color: statusColor, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isConnected && tunnel.primaryEndpoint != null)
                      Text(
                        tunnel.primaryEndpoint!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stats if connected
            if (isConnected) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat(context, '↓', connectionStatus.rxBytesFormatted),
                  _buildStat(context, '↑', connectionStatus.txBytesFormatted),
                  _buildStat(context, '⏱', connectionStatus.connectionDurationString),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Connect/Disconnect button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isConnecting
                    ? null
                    : () => _toggleConnection(ref, tunnel, isConnected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected ? AppColors.error : AppColors.connected,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: Icon(isConnected ? Icons.power_off : Icons.power),
                label: Text(isConnected ? 'Disconnect' : 'Connect'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(BuildContext context, String label, String key) {
    final theme = Theme.of(context);
    final maskedKey = '${key.substring(0, 8)}...${key.substring(key.length - 4)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  maskedKey,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: key));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Copy',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeerCard(BuildContext context, peer) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    peer.endpoint ?? 'No endpoint',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(context, 'Public Key', 
              '${peer.publicKey.substring(0, 8)}...'),
            _buildInfoRow(context, 'Allowed IPs', 
              peer.allowedIPs.join(', ')),
            if (peer.persistentKeepalive != null && peer.persistentKeepalive > 0)
              _buildInfoRow(context, 'Keepalive', 
                '${peer.persistentKeepalive}s'),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitTunnelingCard(BuildContext context, Tunnel tunnel) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.splitscreen),
        title: const Text('Split Tunneling'),
        subtitle: const Text('Configure app exclusions'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/tunnel/$tunnelId/split-tunneling'),
      ),
    );
  }

  void _toggleConnection(WidgetRef ref, Tunnel tunnel, bool isConnected) {
    ref.read(vpnConnectionProvider.notifier).toggle(tunnel);
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Tunnel tunnel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tunnel'),
        content: Text('Are you sure you want to delete "${tunnel.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(tunnelsProvider.notifier).deleteTunnel(tunnel.id);
              if (context.mounted) {
                context.pop();
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _exportConfig(BuildContext context, Tunnel tunnel) {
    final config = tunnel.toConfigString();
    Clipboard.setData(ClipboardData(text: config));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuration copied to clipboard'),
      ),
    );
  }
}
