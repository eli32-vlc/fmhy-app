import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/fm_data_service.dart';
import '../utils/link_actions.dart';
import '../utils/ui_helpers.dart';
import '../views/empty_state.dart';
import '../views/section_header.dart';
import 'category_detail_screen.dart';

/// Browse tab: searchable list of categories plus pure-link entries.
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FMCategory> _apply(List<FMCategory> source, bool Function(FMCategory) test) {
    final filtered = source.where(test).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    if (_query.isEmpty) return filtered;
    final out = <FMCategory>[];
    for (final cat in filtered) {
      try {
        out.add(cat.filter(_query));
      } on StateError {
        // No matches for this category.
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<FMDataService>();
    final categories = data.categories;
    final regular = _apply(categories, (c) => !c.isLink);
    final links = _apply(categories, (c) => c.isLink);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FMHY X'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: data.isLoading ? null : data.refresh,
            icon: data.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search entries…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
              ],
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: data.refresh,
        child: _buildBody(data, regular, links),
      ),
    );
  }

  Widget _buildBody(
    FMDataService data,
    List<FMCategory> regular,
    List<FMCategory> links,
  ) {
    if (data.isLoading && data.categories.isEmpty) {
      // Always scrollable so pull-to-refresh works from any state.
      return ListView(
        children: const [
          SizedBox(height: 160),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (data.error != null && data.categories.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load',
        message: data.error!,
        actionLabel: 'Retry',
        onAction: data.refresh,
      );
    }

    if (data.categories.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_download,
        title: 'No content loaded',
        message: 'Tap refresh to download content',
        actionLabel: 'Refresh',
        onAction: data.refresh,
      );
    }

    if (regular.isEmpty && links.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No results',
        message: 'No entries match "$_query"',
        actionLabel: 'Clear search',
        onAction: () async {
          _searchController.clear();
          setState(() => _query = '');
        },
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (regular.isNotEmpty) ...[
          const SectionHeader('Categories'),
          ...regular.map((c) => _CategoryTile(category: c)),
        ],
        if (links.isNotEmpty) ...[
          const SectionHeader('Links'),
          ...links.map(
            (c) => ListTile(
              leading: _CategoryAvatar(title: c.title),
              title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: c.note == null
                  ? null
                  : Text(
                      stripMarkdown(c.note!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => openLink(c.url!),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final FMCategory category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _CategoryAvatar(title: category.title),
      title: Text(category.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: category.note == null
          ? null
          : Text(
              stripMarkdown(category.note!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${category.totalEntries}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CategoryDetailScreen(category: category),
        ),
      ),
    );
  }
}

class _CategoryAvatar extends StatelessWidget {
  final String title;

  const _CategoryAvatar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: categoryColor(title),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(categoryIcon(title), size: 18, color: Colors.white),
    );
  }
}
