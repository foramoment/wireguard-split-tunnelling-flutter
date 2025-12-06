import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/tunnel.dart';
import '../../models/connection_status.dart';
import '../../providers/tunnel_provider.dart';
import '../../providers/connection_provider.dart';
import '../../widgets/common/tunnel_card.dart';
import '../../widgets/common/empty_tunnel_state.dart';
import '../../core/router/app_router.dart';

/// Home screen showing list of tunnels
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tunnelsAsync = ref.watch(tunnelsProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WireGuard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: tunnelsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load tunnels',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(tunnelsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (tunnels) {
          if (tunnels.isEmpty) {
            return EmptyTunnelState(
              onAddTunnel: () => context.push(AppRoutes.addTunnel),
              onImportTunnel: () => context.push(AppRoutes.importTunnel),
            );
          }

          return _TunnelList(
            tunnels: tunnels,
            connectionStatus: connectionStatus,
            onTunnelTap: (tunnel) {
              context.push('/tunnel/${tunnel.id}');
            },
            onTunnelToggle: (tunnel) {
              _handleToggle(ref, tunnel, connectionStatus);
            },
          );
        },
      ),
      floatingActionButton: tunnelsAsync.maybeWhen(
        data: (tunnels) => tunnels.isNotEmpty
            ? FloatingActionButton(
                onPressed: () => _showAddOptions(context),
                tooltip: 'Add Tunnel',
                child: const Icon(Icons.add),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  void _handleToggle(
    WidgetRef ref,
    Tunnel tunnel,
    ConnectionStatus status,
  ) {
    final notifier = ref.read(connectionStatusProvider.notifier);

    if (status.isConnected && status.tunnelId == tunnel.id) {
      // Disconnect from this tunnel
      notifier.startDisconnecting();
      // TODO: Call actual disconnect service
      Future.delayed(const Duration(milliseconds: 500), () {
        notifier.setDisconnected();
      });
    } else if (status.isConnected && status.tunnelId != tunnel.id) {
      // Already connected to different tunnel - disconnect first, then connect
      notifier.startDisconnecting();
      Future.delayed(const Duration(milliseconds: 500), () {
        notifier.startConnecting(tunnel.id, tunnel.name);
        // TODO: Call actual connect service
        Future.delayed(const Duration(seconds: 1), () {
          notifier.setConnected(
            tunnelId: tunnel.id,
            tunnelName: tunnel.name,
            endpoint: tunnel.primaryEndpoint,
          );
        });
      });
    } else {
      // Not connected - connect to this tunnel
      notifier.startConnecting(tunnel.id, tunnel.name);
      // TODO: Call actual connect service
      Future.delayed(const Duration(seconds: 1), () {
        notifier.setConnected(
          tunnelId: tunnel.id,
          tunnelName: tunnel.name,
          endpoint: tunnel.primaryEndpoint,
        );
      });
    }
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create New Tunnel'),
                subtitle: const Text('Manually enter configuration'),
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.addTunnel);
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_upload_outlined),
                title: const Text('Import from File'),
                subtitle: const Text('Import .conf file'),
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.importTunnel);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget displaying the list of tunnels
class _TunnelList extends StatelessWidget {
  final List<Tunnel> tunnels;
  final ConnectionStatus connectionStatus;
  final void Function(Tunnel) onTunnelTap;
  final void Function(Tunnel) onTunnelToggle;

  const _TunnelList({
    required this.tunnels,
    required this.connectionStatus,
    required this.onTunnelTap,
    required this.onTunnelToggle,
  });

  VpnConnectionState _getConnectionState(Tunnel tunnel) {
    if (connectionStatus.tunnelId != tunnel.id) {
      return VpnConnectionState.disconnected;
    }
    return connectionStatus.state;
  }

  @override
  Widget build(BuildContext context) {
    // Sort tunnels: connected first, then by name
    final sortedTunnels = List<Tunnel>.from(tunnels)
      ..sort((a, b) {
        final aConnected = connectionStatus.tunnelId == a.id;
        final bConnected = connectionStatus.tunnelId == b.id;
        if (aConnected != bConnected) {
          return aConnected ? -1 : 1;
        }
        return a.name.compareTo(b.name);
      });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: sortedTunnels.length,
      itemBuilder: (context, index) {
        final tunnel = sortedTunnels[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TunnelCard(
            name: tunnel.name,
            endpoint: tunnel.primaryEndpoint,
            connectionState: _getConnectionState(tunnel),
            onTap: () => onTunnelTap(tunnel),
            onToggle: () => onTunnelToggle(tunnel),
          ),
        );
      },
    );
  }
}
