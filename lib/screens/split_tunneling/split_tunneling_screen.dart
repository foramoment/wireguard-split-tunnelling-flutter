import 'package:flutter/material.dart';

/// Split tunneling configuration screen
class SplitTunnelingScreen extends StatelessWidget {
  final String tunnelId;

  const SplitTunnelingScreen({
    super.key,
    required this.tunnelId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Tunneling'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Enable switch
          Card(
            child: SwitchListTile(
              title: const Text('Enable Split Tunneling'),
              subtitle: const Text('Exclude specific apps from VPN'),
              value: false,
              onChanged: (value) {
                // TODO: Toggle split tunneling
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Mode selection
          Card(
            child: Column(
              children: [
                RadioListTile<int>(
                  title: const Text('Exclude Mode'),
                  subtitle: const Text('VPN for all except listed apps'),
                  value: 0,
                  groupValue: 0,
                  onChanged: (value) {},
                ),
                RadioListTile<int>(
                  title: const Text('Include Mode'),
                  subtitle: const Text('VPN only for listed apps'),
                  value: 1,
                  groupValue: 0,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Apps section
          Text(
            'Excluded Apps',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Application'),
              onTap: () {
                // TODO: Open app picker
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Folders section
          Text(
            'Excluded Folders',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Add Folder'),
              subtitle: const Text('All executables in folder will be excluded'),
              onTap: () {
                // TODO: Open folder picker
              },
            ),
          ),
        ],
      ),
    );
  }
}
