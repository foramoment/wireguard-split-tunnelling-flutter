import 'package:flutter/material.dart';

/// App settings screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: const Text('System'),
            onTap: () {
              // TODO: Show theme picker
            },
          ),
          const Divider(),
          
          // Notifications
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Show connection status notifications'),
            value: true,
            onChanged: (value) {
              // TODO: Toggle notifications
            },
          ),
          const Divider(),
          
          // Auto-start
          SwitchListTile(
            secondary: const Icon(Icons.play_arrow_outlined),
            title: const Text('Auto-start'),
            subtitle: const Text('Start app with system'),
            value: false,
            onChanged: (value) {
              // TODO: Toggle auto-start
            },
          ),
          const Divider(),
          
          // Logs
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Logs'),
            subtitle: const Text('View application logs'),
            onTap: () {
              // TODO: Navigate to logs
            },
          ),
          const Divider(),
          
          // About
          ListTile(
            leading: const Icon(Icons.info_outlined),
            title: const Text('About'),
            subtitle: const Text('Version 0.1.0'),
            onTap: () {
              // TODO: Show about dialog
            },
          ),
        ],
      ),
    );
  }
}
