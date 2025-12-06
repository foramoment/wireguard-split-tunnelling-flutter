import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../models/tunnel.dart';
import '../../providers/tunnel_provider.dart';
import '../../utils/config_parser.dart';
import '../../core/theme/app_colors.dart';

/// Screen for importing tunnel from .conf file
class ImportTunnelScreen extends ConsumerStatefulWidget {
  const ImportTunnelScreen({super.key});

  @override
  ConsumerState<ImportTunnelScreen> createState() => _ImportTunnelScreenState();
}

class _ImportTunnelScreenState extends ConsumerState<ImportTunnelScreen> {
  String? _fileName;
  String? _fileContent;
  Tunnel? _parsedTunnel;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSaving = false;

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['conf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final file = result.files.first;
      _fileName = file.name;

      String content;
      if (file.bytes != null) {
        content = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        throw Exception('Could not read file content');
      }

      _fileContent = content;

      // Parse the config
      final tunnelName = file.name.replaceAll('.conf', '');
      final tunnel = WireGuardConfigParser.parse(content, name: tunnelName);

      setState(() {
        _parsedTunnel = tunnel;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _parsedTunnel = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _importTunnel() async {
    if (_parsedTunnel == null) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(tunnelsProvider.notifier).addTunnel(_parsedTunnel!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported "${_parsedTunnel!.name}"'),
            backgroundColor: AppColors.connected,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Tunnel'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File picker area
            _buildFilePicker(theme),
            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null) ...[
              _buildErrorCard(theme),
              const SizedBox(height: 24),
            ],

            // Parsed tunnel preview
            if (_parsedTunnel != null) ...[
              _buildTunnelPreview(theme),
              const SizedBox(height: 24),

              // Import button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _importTunnel,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSaving ? 'Importing...' : 'Import Tunnel'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: _isLoading ? null : _pickFile,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.dividerColor,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.primary.withAlpha(isDark ? 15 : 10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator()
            else ...[
              Icon(
                _fileName != null
                    ? Icons.description_outlined
                    : Icons.file_upload_outlined,
                size: 48,
                color: theme.colorScheme.primary.withAlpha(179),
              ),
              const SizedBox(height: 16),
              Text(
                _fileName ?? 'Select .conf file',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _fileName != null
                    ? 'Tap to select a different file'
                    : 'Tap to browse your files',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withAlpha(179),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Card(
      color: AppColors.error.withAlpha(25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parse Error',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _errorMessage!,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTunnelPreview(ThemeData theme) {
    final tunnel = _parsedTunnel!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.connected,
                ),
                const SizedBox(width: 8),
                Text(
                  'Configuration Valid',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.connected,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Tunnel name
            _buildInfoRow(theme, 'Name', tunnel.name),
            const SizedBox(height: 12),

            // Address
            _buildInfoRow(
              theme,
              'Address',
              tunnel.addresses.join(', '),
            ),
            const SizedBox(height: 12),

            // DNS
            if (tunnel.dns != null && tunnel.dns!.isNotEmpty) ...[
              _buildInfoRow(
                theme,
                'DNS',
                tunnel.dns!.join(', '),
              ),
              const SizedBox(height: 12),
            ],

            // Peers
            _buildInfoRow(
              theme,
              'Peers',
              '${tunnel.peers.length}',
            ),

            // First peer endpoint
            if (tunnel.peers.isNotEmpty &&
                tunnel.peers.first.endpoint != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                theme,
                'Endpoint',
                tunnel.peers.first.endpoint!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withAlpha(179),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
