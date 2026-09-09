import 'package:flutter/material.dart';

import '../models/deliverable.dart';
import '../theme/app_theme.dart';

/// Collapsible list of deliverables the user has marked unavailable.
/// Tapping the restore icon returns an item to its original position in
/// the main list and removes any alternative tile it spawned.
class UnavailableSection extends StatelessWidget {
  final List<DeliverableItem> items;
  final void Function(String id) onRestore;

  const UnavailableSection({
    super.key,
    required this.items,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        iconColor: AppColors.accent,
        collapsedIconColor: AppColors.accent,
        title: Row(
          children: [
            const Icon(Icons.visibility_off, color: AppColors.accent, size: 18),
            const SizedBox(width: 8),
            Text(
              'Unavailable Items (${items.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
        children: items
            .map(
              (item) => ListTile(
                dense: true,
                title: Text(
                  item.name,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                trailing: TextButton.icon(
                  onPressed: () => onRestore(item.id),
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('Restore'),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
