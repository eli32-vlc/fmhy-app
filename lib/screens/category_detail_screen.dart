import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/ui_helpers.dart';
import '../views/entry_row.dart';
import '../views/section_header.dart';

/// Detail view for one category: optional note, general entries, then sections.
class CategoryDetailScreen extends StatelessWidget {
  final FMCategory category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.title)),
      body: ListView(
        children: [
          if (category.note != null)
            NoteBox(text: stripMarkdown(category.note!)),
          if (category.entries.isNotEmpty) ...[
            const SectionHeader('General'),
            ...category.entries.map((e) => EntryRow(entry: e)),
          ],
          for (final section in category.sections) ...[
            SectionHeader(section.title),
            if (section.note != null)
              NoteBox(text: stripMarkdown(section.note!)),
            ...section.entries.map((e) => EntryRow(entry: e)),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
