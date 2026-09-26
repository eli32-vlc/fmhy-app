import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import '../services/fm_favorites_service.dart';
import '../services/fm_history_service.dart';
import '../utils/link_actions.dart';
import '../utils/ui_helpers.dart';

/// A single link row: badge, name, description, plus share/copy/favorite actions.
class EntryRow extends StatelessWidget {
  final FMEntry entry;

  const EntryRow({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final history = context.read<FMHistoryService>();
    final favorites = context.watch<FMFavoritesService>();
    final isFav = favorites.isFavorite(entry.url);

    Future<void> open() async {
      await history.recordView(entry.name, entry.url);
      if (!context.mounted) return;
      await openLink(entry.url);
    }

    return InkWell(
      onTap: open,
      onLongPress: () => _showActions(context, open, isFav),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.badge != FMBadge.none)
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 10),
                child: Icon(
                  badgeIcon(entry.badge.name),
                  size: 16,
                  color: badgeColor(entry.badge.name),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (entry.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        entry.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (entry.relatedLinks.isNotEmpty)
              _RelatedMenu(entry: entry, onOpen: open)
            else if (isFav)
              const Icon(Icons.star, size: 16, color: Colors.amber),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context, Future<void> Function() open, bool isFav) {
    final history = context.read<FMHistoryService>();
    final favorites = context.read<FMFavoritesService>();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open'),
              onTap: () {
                Navigator.pop(ctx);
                open();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy URL'),
              onTap: () {
                Navigator.pop(ctx);
                copyUrl(entry.url);
                _toast(ctx, 'URL copied');
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(ctx);
                SharePlus.instance.share(
                  ShareParams(text: '${entry.name}\n${entry.url}'),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(isFav ? Icons.star_outline : Icons.star),
              title: Text(isFav ? 'Remove from Favorites' : 'Add to Favorites'),
              onTap: () {
                Navigator.pop(ctx);
                favorites.toggle(entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Remove from History'),
              onTap: () {
                Navigator.pop(ctx);
                history.remove(entry.url);
              },
            ),
          ],
        ),
      ),
    );
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Popup menu for the alternate links attached to one entry.
class _RelatedMenu extends StatelessWidget {
  final FMEntry entry;
  final Future<void> Function() onOpen;

  const _RelatedMenu({required this.entry, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final history = context.read<FMHistoryService>();
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      padding: EdgeInsets.zero,
      tooltip: 'Other links',
      onSelected: (value) async {
        if (value == entry.url) return onOpen();
        final link = entry.relatedLinks.firstWhere((l) => l.url == value);
        await history.recordView(link.name, link.url);
        await openLink(link.url);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: entry.url,
          child: Row(
            children: [
              const Icon(Icons.open_in_new, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(entry.name, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        ...entry.relatedLinks.map(
          (link) => PopupMenuItem(
            value: link.url,
            child: Text(link.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}
