import 'package:flutter/material.dart';

/// Shared empty / error state used across tabs.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  /// Optional action button, typically a retry.
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: () => _confirm(context),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionLabel!),
          ),
        ],
      ),
    );
    if (ok == true) await onAction!();
  }
}
