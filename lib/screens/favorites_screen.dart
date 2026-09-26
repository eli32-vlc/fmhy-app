import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/fm_favorites_service.dart';
import '../services/fm_history_service.dart';
import '../utils/link_actions.dart';
import '../utils/ui_helpers.dart';
import '../views/empty_state.dart';

/// Favorites tab: starred entries, swipe or long-press to remove.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FMFavoritesService>();
    final history = context.read<FMHistoryService>();
    final entries = favorites.favorites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear favorites',
              onPressed: () => _confirmClear(context),
            ),
        ],
      ),
      body: entries.isEmpty
          ? const EmptyState(
              icon: Icons.star,
              title: 'No Favorites',
              message: 'Long-press an entry to star it',
            )
          : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
              itemBuilder: (context, index) {
                final fav = entries[index];
                return Dismissible(
                  key: ValueKey(fav.url),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: Icon(
                      Icons.star_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  onDismissed: (_) => favorites.remove(fav.url),
                  child: ListTile(
                    leading: fav.badge == FMBadge.none
                        ? const Icon(Icons.star, size: 18, color: Colors.amber)
                        : Icon(
                            badgeIcon(fav.badge.name),
                            size: 18,
                            color: badgeColor(fav.badge.name),
                          ),
                    title: Text(
                      fav.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () {
                      history.recordView(fav.name, fav.url);
                      openLink(fav.url);
                    },
                    onLongPress: () => favorites.remove(fav.url),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final favorites = context.read<FMFavoritesService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Favorites'),
        content: const Text('This will remove all favorited entries.'),
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
    if (ok == true) await favorites.clear();
  }
}
