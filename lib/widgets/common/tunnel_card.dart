import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/connection_status.dart' show VpnConnectionState;

/// A card widget representing a WireGuard tunnel
class TunnelCard extends StatelessWidget {
  final String name;
  final String? endpoint;
  final VpnConnectionState connectionState;
  final int? splitTunnelAppCount;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onSplitTunnelTap;

  const TunnelCard({
    super.key,
    required this.name,
    this.endpoint,
    this.connectionState = VpnConnectionState.disconnected,
    this.splitTunnelAppCount,
    this.onTap,
    this.onToggle,
    this.onSplitTunnelTap,
  });

  Color get _statusColor {
    switch (connectionState) {
      case VpnConnectionState.connected:
        return AppColors.connected;
      case VpnConnectionState.connecting:
      case VpnConnectionState.disconnecting:
        return AppColors.connecting;
      case VpnConnectionState.error:
        return AppColors.error;
      case VpnConnectionState.disconnected:
        return AppColors.disconnected;
    }
  }

  IconData get _statusIcon {
    switch (connectionState) {
      case VpnConnectionState.connected:
        return Icons.shield;
      case VpnConnectionState.connecting:
      case VpnConnectionState.disconnecting:
        return Icons.sync;
      case VpnConnectionState.error:
        return Icons.error_outline;
      case VpnConnectionState.disconnected:
        return Icons.shield_outlined;
    }
  }

  String get _statusText {
    switch (connectionState) {
      case VpnConnectionState.connected:
        return 'Connected';
      case VpnConnectionState.connecting:
        return 'Connecting...';
      case VpnConnectionState.disconnecting:
        return 'Disconnecting...';
      case VpnConnectionState.error:
        return 'Error';
      case VpnConnectionState.disconnected:
        return 'Disconnected';
    }
  }

  bool get _isConnected => connectionState == VpnConnectionState.connected;
  bool get _isBusy =>
      connectionState == VpnConnectionState.connecting ||
      connectionState == VpnConnectionState.disconnecting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: _isConnected
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.connected.withAlpha(isDark ? 30 : 20),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _statusColor.withAlpha(isDark ? 40 : 25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isBusy
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(_statusColor),
                          ),
                        )
                      : Icon(
                          _statusIcon,
                          color: _statusColor,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),

                // Tunnel info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _statusText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _statusColor,
                            ),
                          ),
                          if (endpoint != null && _isConnected) ...[
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withAlpha(128),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                endpoint!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withAlpha(179),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Split tunneling indicator
                if (splitTunnelAppCount != null && splitTunnelAppCount! > 0) ...[
                  InkWell(
                    onTap: onSplitTunnelTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withAlpha(isDark ? 40 : 25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.splitscreen,
                            size: 14,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$splitTunnelAppCount',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Toggle switch
                Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: _isConnected,
                    onChanged: _isBusy ? null : (_) => onToggle?.call(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
