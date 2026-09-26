import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/fm_data_service.dart';
import '../services/fm_favorites_service.dart';
import '../services/fm_history_service.dart';
import '../views/section_header.dart';

enum _DataKind { favorites, history }

/// Settings tab: refresh, JSON export/import, clear all, and app info.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FMDataService>();
    final favorites = context.read<FMFavoritesService>();
    final history = context.read<FMHistoryService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Force Refresh'),
            subtitle: data.lastUpdated == null
                ? null
                : Text('Updated ${_stamp(data.lastUpdated!)}'),
            trailing: data.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: data.isLoading ? null : data.refresh,
          ),
          const SectionHeader('Export'),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('Export Favorites'),
            onTap: () => _export(context, _DataKind.favorites, favorites),
          ),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('Export Recently Viewed'),
            onTap: () => _export(context, _DataKind.history, history),
          ),
          const SectionHeader('Import'),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Import Favorites'),
            onTap: () => _import(context, _DataKind.favorites, favorites),
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Import Recently Viewed'),
            onTap: () => _import(context, _DataKind.history, history),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Clear Everything',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _clearAll(context, data, favorites, history),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Source'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(
              Uri.parse('https://fmhy.net'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            trailing: Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  static String _stamp(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _export(
    BuildContext context,
    _DataKind kind,
    dynamic service,
  ) async {
    final contents = kind == _DataKind.favorites
        ? (service as FMFavoritesService).exportJson()
        : (service as FMHistoryService).exportJson();
    final name = kind == _DataKind.favorites
        ? 'fmhy_favorites.json'
        : 'fmhy_history.json';

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(contents);
    if (!context.mounted) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: name),
    );
  }

  Future<void> _import(
    BuildContext context,
    _DataKind kind,
    dynamic service,
  ) async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    try {
      final decoded = jsonDecode(utf8.decode(bytes)) as List;
      if (kind == _DataKind.favorites) {
        final entries = decoded
            .map((e) => FavoriteEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        await (service as FMFavoritesService).importAll(entries);
      } else {
        final entries = decoded
            .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        await (service as FMHistoryService).importAll(entries);
      }
      if (context.mounted) _toast(context, 'Import complete');
    } catch (_) {
      if (context.mounted) _toast(context, 'Invalid ${kind.name} file');
    }
  }

  Future<void> _clearAll(
    BuildContext context,
    FMDataService data,
    FMFavoritesService favorites,
    FMHistoryService history,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Everything'),
        content: const Text('This will remove all cache, history, and favorites.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await data.clearCache();
    await history.clear();
    await favorites.clear();
    if (context.mounted) _toast(context, 'Cleared');
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
