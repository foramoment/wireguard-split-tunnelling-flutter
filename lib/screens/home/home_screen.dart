import 'package:flutter/material.dart';

/// Home screen showing list of tunnels
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WireGuard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.vpn_key_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withAlpha(128),
            ),
            const SizedBox(height: 24),
            Text(
              'No Tunnels Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first WireGuard tunnel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to add tunnel
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Tunnel'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add tunnel
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
