import 'package:flutter/material.dart';

/// Tunnel details screen showing full configuration and stats
class TunnelDetailsScreen extends StatelessWidget {
  final String tunnelId;

  const TunnelDetailsScreen({
    super.key,
    required this.tunnelId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tunnel Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: Navigate to edit tunnel
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // TODO: Show delete confirmation
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Tunnel: $tunnelId'),
      ),
    );
  }
}
