import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/fm_history_service.dart';
import '../utils/link_actions.dart';
import '../utils/ui_helpers.dart';
import '../views/empty_state.dart';

/// Recently Viewed tab.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<FMHistoryService>();
    final entries = history.entries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Viewed'),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear history',
              onPressed: () => _confirmClear(context),
            ),
        ],
      ),
      body: entries.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              title: 'No Recently Viewed',
              message: 'Entries you open will appear here',
            )
          : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ListTile(
                  leading: const Icon(Icons.history, size: 18),
                  title: Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(relativeTime(entry.viewedAt)),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () {
                    history.recordView(entry.name, entry.url);
                    openLink(entry.url);
                  },
                  onLongPress: () => history.remove(entry.url),
                );
              },
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final history = context.read<FMHistoryService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('This will remove all recently viewed entries.'),
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
    if (ok == true) await history.clear();
  }
}
