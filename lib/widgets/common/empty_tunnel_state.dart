import 'package:flutter/material.dart';

/// Empty state widget shown when there are no tunnels
class EmptyTunnelState extends StatelessWidget {
  final VoidCallback? onAddTunnel;
  final VoidCallback? onImportTunnel;

  const EmptyTunnelState({
    super.key,
    this.onAddTunnel,
    this.onImportTunnel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(isDark ? 30 : 20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.vpn_key_outlined,
                size: 56,
                color: theme.colorScheme.primary.withAlpha(179),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              'No Tunnels Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Add your first WireGuard tunnel to get started.\nYou can create a new one or import from a .conf file.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Create new
                ElevatedButton.icon(
                  onPressed: onAddTunnel,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Create New'),
                ),
                const SizedBox(width: 12),

                // Import
                OutlinedButton.icon(
                  onPressed: onImportTunnel,
                  icon: const Icon(Icons.file_upload_outlined, size: 20),
                  label: const Text('Import'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
