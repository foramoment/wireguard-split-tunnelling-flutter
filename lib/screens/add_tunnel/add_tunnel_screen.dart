import 'package:flutter/material.dart';

/// Screen for adding or editing a tunnel
class AddTunnelScreen extends StatelessWidget {
  final String? tunnelId;

  const AddTunnelScreen({
    super.key,
    this.tunnelId,
  });

  bool get isEditing => tunnelId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Tunnel' : 'Add Tunnel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // TODO: Add form fields
            const Text('Tunnel configuration form'),
          ],
        ),
      ),
    );
  }
}
