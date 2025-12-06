import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/split_tunnel_config.dart';

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
  
  bool _enabled = false;
  SplitTunnelMode _mode = SplitTunnelMode.exclude;
  
  // Mock data for demo
  final List<AppInfo> _selectedApps = [];
  final List<SplitTunnelFolder> _folders = [];

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Tunneling'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _buildEnableToggle(theme),
          ),
        ),
      ),
      body: Column(
        children: [
          // Mode selector
          if (_enabled) ...[
            _buildModeSelector(theme),
            
            // Tabs
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  icon: const Icon(Icons.apps),
                  text: 'Apps (${_selectedApps.length})',
                ),
                Tab(
                  icon: const Icon(Icons.folder),
                  text: 'Folders (${_folders.length})',
                ),
              ],
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAppsTab(theme),
                  _buildFoldersTab(theme),
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

  Widget _buildEnableToggle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _enabled 
            ? AppColors.connected.withAlpha(25)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _enabled ? Icons.splitscreen : Icons.block,
            color: _enabled ? AppColors.connected : theme.iconTheme.color,
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
                  _enabled ? 'Active' : 'Disabled',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _enabled ? AppColors.connected : null,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(ThemeData theme) {
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
    SplitTunnelMode mode,
    IconData icon,
    String title,
    String description,
  ) {
    final isSelected = _mode == mode;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _mode = mode),
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

  Widget _buildAppsTab(ThemeData theme) {
    if (_selectedApps.isEmpty) {
      return _buildEmptyState(
        theme,
        Icons.apps,
        'No Apps Selected',
        'Add applications to ${_mode == SplitTunnelMode.exclude ? "exclude from" : "include in"} VPN',
        'Add Apps',
        _showAppPicker,
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _selectedApps.length,
            itemBuilder: (context, index) {
              final app = _selectedApps[index];
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
                      setState(() => _selectedApps.removeAt(index));
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

  Widget _buildFoldersTab(ThemeData theme) {
    if (_folders.isEmpty) {
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
            itemCount: _folders.length,
            itemBuilder: (context, index) {
              final folder = _folders[index];
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
                          setState(() => _folders.removeAt(index));
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
              onPressed: () => setState(() => _enabled = true),
              icon: const Icon(Icons.power_settings_new),
              label: const Text('Enable'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppPicker() {
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
              setState(() {
                _selectedApps.add(AppInfo(
                  id: 'com.example.app${_selectedApps.length + 1}',
                  name: 'Demo App ${_selectedApps.length + 1}',
                  path: 'C:\\Program Files\\DemoApp\\app.exe',
                ));
              });
            },
            child: const Text('Add Demo App'),
          ),
        ],
      ),
    );
  }

  void _addFolder() {
    // TODO: Implement folder picker using file_picker
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Folder'),
        content: const Text(
          'Folder picker will let you select a directory.\n\n'
          'For demo, we\'ll add a sample folder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _folders.add(SplitTunnelFolder(
                  id: 'folder${_folders.length + 1}',
                  path: 'C:\\Games\\Steam',
                  name: 'Steam',
                  discoveredApps: ['steam.exe', 'steamwebhelper.exe'],
                  lastScanned: DateTime.now(),
                ));
              });
            },
            child: const Text('Add Demo Folder'),
          ),
        ],
      ),
    );
  }

  void _rescanFolder(SplitTunnelFolder folder) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rescanning ${folder.name}...')),
    );
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
