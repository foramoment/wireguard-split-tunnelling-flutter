import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/settings_provider.dart';
import '../../core/theme/app_colors.dart';

/// Settings screen with app preferences
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Appearance Section
          _buildSectionHeader(theme, 'Appearance'),
          _buildThemeTile(context, ref, settings),
          const Divider(height: 1),

          // Behavior Section
          _buildSectionHeader(theme, 'Behavior'),
          SwitchListTile(
            title: const Text('Auto-connect on startup'),
            subtitle: const Text('Connect to last used tunnel when app starts'),
            secondary: const Icon(Icons.play_circle_outline),
            value: settings.autoStartEnabled,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setAutoStartEnabled(v),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Start minimized'),
            subtitle: const Text('Start in system tray instead of window'),
            secondary: const Icon(Icons.minimize),
            value: settings.startMinimized,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setStartMinimized(v),
          ),
          const Divider(height: 1),

          // Notifications Section
          _buildSectionHeader(theme, 'Notifications'),
          SwitchListTile(
            title: const Text('Enable notifications'),
            subtitle: const Text('Show connection status notifications'),
            secondary: const Icon(Icons.notifications_outlined),
            value: settings.notificationsEnabled,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setNotificationsEnabled(v),
          ),
          const Divider(height: 1),

          // Security Section
          _buildSectionHeader(theme, 'Security'),
          SwitchListTile(
            title: const Text('Kill Switch'),
            subtitle: const Text('Block internet if VPN disconnects unexpectedly'),
            secondary: const Icon(Icons.block),
            value: settings.killSwitchEnabled,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setKillSwitchEnabled(v),
          ),
          const Divider(height: 1),

          // About Section
          _buildSectionHeader(theme, 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: const Text('0.1.0 (Development)'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Source Code'),
            subtitle: const Text('View on GitHub'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _launchUrl('https://github.com'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: const Text('WireGuard'),
            subtitle: const Text('Learn more about the protocol'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _launchUrl('https://www.wireguard.com'),
          ),
          const Divider(height: 1),

          // Danger Zone
          _buildSectionHeader(theme, 'Danger Zone', isDanger: true),
          ListTile(
            leading: Icon(Icons.delete_forever, color: AppColors.error),
            title: Text(
              'Delete all tunnels',
              style: TextStyle(color: AppColors.error),
            ),
            subtitle: const Text('Remove all saved tunnel configurations'),
            onTap: () => _showDeleteAllDialog(context, ref),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, {bool isDanger = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: isDanger ? AppColors.error : theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, WidgetRef ref, SettingsState settings) {
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: const Text('Theme'),
      subtitle: Text(_getThemeModeName(settings.themeMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context, ref, settings),
    );
  }

  String _getThemeModeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'System default';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, SettingsState settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return RadioListTile<AppThemeMode>(
              title: Text(_getThemeModeName(mode)),
              value: mode,
              groupValue: settings.themeMode,
              onChanged: (v) {
                ref.read(settingsProvider.notifier).setThemeMode(v!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDeleteAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Tunnels'),
        content: const Text(
          'Are you sure you want to delete all tunnel configurations? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement delete all
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All tunnels deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}
