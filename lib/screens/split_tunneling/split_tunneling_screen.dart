import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../models/split_tunnel_config.dart';
import '../../services/folder_scanner_service.dart';
import '../../providers/split_tunnel_provider.dart';

/// Split tunneling configuration screen
class SplitTunnelingScreen extends ConsumerStatefulWidget {
  final String? tunnelId;

  const SplitTunnelingScreen({super.key, this.tunnelId});

  @override
  ConsumerState<SplitTunnelingScreen> createState() => _SplitTunnelingScreenState();
}

class _SplitTunnelingScreenState extends ConsumerState<SplitTunnelingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  /// Get the config ID - use tunnelId if provided, otherwise global
  String get _configId => widget.tunnelId ?? globalSplitTunnelId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = ref.watch(splitTunnelConfigProvider(_configId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Tunneling'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _buildEnableToggle(theme, config),
          ),
        ),
      ),
      body: Column(
        children: [
          // Mode selector
          if (config.enabled) ...[
            _buildModeSelector(theme, config),
            
            // Tabs
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  icon: const Icon(Icons.apps),
                  text: 'Apps (${config.apps.length})',
                ),
                Tab(
                  icon: const Icon(Icons.folder),
                  text: 'Folders (${config.folders.length})',
                ),
              ],
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAppsTab(theme, config),
                  _buildFoldersTab(theme, config),
                ],
              ),
            ),
          ] else ...[
            Expanded(
              child: _buildDisabledState(theme),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnableToggle(ThemeData theme, SplitTunnelConfig config) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: config.enabled 
            ? AppColors.connected.withAlpha(25)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            config.enabled ? Icons.splitscreen : Icons.block,
            color: config.enabled ? AppColors.connected : theme.iconTheme.color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Split Tunneling',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  config.enabled ? 'Active' : 'Disabled',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: config.enabled ? AppColors.connected : null,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: config.enabled,
            onChanged: (v) => ref.read(splitTunnelConfigProvider(_configId).notifier).setEnabled(v),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(ThemeData theme, SplitTunnelConfig config) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mode',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildModeCard(
                  theme,
                  config,
                  SplitTunnelMode.exclude,
                  Icons.remove_circle_outline,
                  'Exclude',
                  'All traffic through VPN except selected apps',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeCard(
                  theme,
                  config,
                  SplitTunnelMode.include,
                  Icons.add_circle_outline,
                  'Include',
                  'Only selected apps through VPN',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(
    ThemeData theme,
    SplitTunnelConfig config,
    SplitTunnelMode mode,
    IconData icon,
    String title,
    String description,
  ) {
    final isSelected = config.mode == mode;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => ref.read(splitTunnelConfigProvider(_configId).notifier).setMode(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary 
                : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primary.withAlpha(isDark ? 30 : 20)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppsTab(ThemeData theme, SplitTunnelConfig config) {
    if (config.apps.isEmpty) {
      return _buildEmptyState(
        theme,
        Icons.apps,
        'No Apps Selected',
        'Add applications to ${config.mode == SplitTunnelMode.exclude ? "exclude from" : "include in"} VPN',
        'Add Apps',
        _showAppPicker,
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: config.apps.length,
            itemBuilder: (context, index) {
              final app = config.apps[index];
              return Card(
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.android),
                  ),
                  title: Text(app.name),
                  subtitle: Text(app.path ?? app.id),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.error,
                    onPressed: () {
                      ref.read(splitTunnelConfigProvider(_configId).notifier).removeApp(app.id);
                    },
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showAppPicker,
            icon: const Icon(Icons.add),
            label: const Text('Add More Apps'),
          ),
        ),
      ],
    );
  }

  Widget _buildFoldersTab(ThemeData theme, SplitTunnelConfig config) {
    if (config.folders.isEmpty) {
      return _buildEmptyState(
        theme,
        Icons.folder_open,
        'No Folders Added',
        'Add folders containing applications to automatically include all executables',
        'Add Folder',
        _addFolder,
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: config.folders.length,
            itemBuilder: (context, index) {
              final folder = config.folders[index];
              return Card(
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.folder),
                  ),
                  title: Text(folder.name),
                  subtitle: Text(
                    '${folder.discoveredApps.length} apps found • ${folder.path}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => _rescanFolder(folder),
                        tooltip: 'Rescan',
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.error,
                        onPressed: () {
                          ref.read(splitTunnelConfigProvider(_configId).notifier).removeFolder(folder.id);
                        },
                      ),
                    ],
                  ),
                  onTap: () => _showFolderApps(folder),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _addFolder,
            icon: const Icon(Icons.create_new_folder),
            label: const Text('Add Folder'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    IconData icon,
    String title,
    String description,
    String buttonText,
    VoidCallback onPressed,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: theme.colorScheme.primary.withAlpha(179),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.splitscreen,
                size: 48,
                color: theme.iconTheme.color?.withAlpha(128),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Split Tunneling Disabled',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enable split tunneling to choose which apps\nuse the VPN connection',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => ref.read(splitTunnelConfigProvider(_configId).notifier).setEnabled(true),
              icon: const Icon(Icons.power_settings_new),
              label: const Text('Enable'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppPicker() {
    final config = ref.read(splitTunnelConfigProvider(_configId));
    // TODO: Implement actual app picker using platform-specific code
    // For now, add a demo app
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Application'),
        content: const Text(
          'App picker will scan installed applications.\n\n'
          'For demo, we\'ll add a sample app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final appNum = config.apps.length + 1;
              ref.read(splitTunnelConfigProvider(_configId).notifier).addApp(
                AppInfo(
                  id: 'com.example.app$appNum',
                  name: 'Demo App $appNum',
                  path: 'C:\\Program Files\\DemoApp\\app.exe',
                ),
              );
            },
            child: const Text('Add Demo App'),
          ),
        ],
      ),
    );
  }

  Future<void> _addFolder() async {
    final config = ref.read(splitTunnelConfigProvider(_configId));
    // Use file_picker to select a directory
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select folder to scan for applications',
    );

    if (result == null) return; // User cancelled

    // Check if folder already added
    if (config.folders.any((f) => f.path == result)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This folder is already added')),
        );
      }
      return;
    }

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scanning folder for executables...')),
      );
    }

    // Scan the folder
    final scanner = FolderScannerService();
    final folder = await scanner.createFolderConfig(result);

    // Add to provider (persists automatically)
    await ref.read(splitTunnelConfigProvider(_configId).notifier).addFolder(folder);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${folder.discoveredApps.length} executables in ${folder.name}'),
          backgroundColor: AppColors.connected,
        ),
      );
    }
  }

  Future<void> _rescanFolder(SplitTunnelFolder folder) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rescanning ${folder.name}...')),
    );

    final scanner = FolderScannerService();
    final updatedFolder = await scanner.rescanFolder(folder);

    // Update folder in provider (persists automatically)
    await ref.read(splitTunnelConfigProvider(_configId).notifier).updateFolder(updatedFolder);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${updatedFolder.discoveredApps.length} executables'),
          backgroundColor: AppColors.connected,
        ),
      );
    }
  }

  void _showFolderApps(SplitTunnelFolder folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${folder.name} - ${folder.discoveredApps.length} apps',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ...folder.discoveredApps.map((app) => ListTile(
              leading: const Icon(Icons.apps),
              title: Text(app),
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
