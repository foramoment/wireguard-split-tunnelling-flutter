import 'package:flutter/material.dart';

/// Screen for importing tunnel from .conf file
class ImportTunnelScreen extends StatelessWidget {
  const ImportTunnelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Tunnel'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.file_upload_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withAlpha(128),
            ),
            const SizedBox(height: 24),
            Text(
              'Import Configuration',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Select a .conf file to import',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Open file picker
              },
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose File'),
            ),
          ],
        ),
      ),
    );
  }
}
