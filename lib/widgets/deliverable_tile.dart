import 'package:flutter/material.dart';

import '../models/deliverable.dart';
import '../theme/app_theme.dart';

/// Renders a single deliverable (or Alternative tile) as a card with:
///  - a completion checkbox on the left,
///  - the name + a "More Info" (+) expander in the middle,
///  - an availability switch on the right (when applicable),
///  - an animated expanding panel with descriptive guidance.
class DeliverableTile extends StatelessWidget {
  final DeliverableItem item;
  final VoidCallback onToggleCompleted;
  final VoidCallback onToggleExpanded;
  final VoidCallback? onToggleAvailability;

  const DeliverableTile({
    super.key,
    required this.item,
    required this.onToggleCompleted,
    required this.onToggleExpanded,
    this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: item.isAlternativeTile
            ? const BorderSide(color: AppColors.accent, width: 1.2)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              children: [
                Checkbox(
                  value: item.isCompleted,
                  onChanged: (_) => onToggleCompleted(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15.5,
                                decoration: item.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: item.isCompleted
                                    ? AppColors.mutedText
                                    : AppColors.primaryText,
                              ),
                            ),
                          ),
                          if (item.isMandatory && !item.isAlternativeTile)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: _MandatoryBadge(),
                            ),
                        ],
                      ),
                      if (item.isAlternativeTile)
                        const Text(
                          'Replacement deliverable',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.accent,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                if (item.hasMoreInfo)
                  IconButton(
                    tooltip: 'More Info',
                    icon: Icon(
                      item.isExpanded ? Icons.remove_circle : Icons.add_circle,
                      color: AppColors.primary,
                    ),
                    onPressed: onToggleExpanded,
                  ),
                if (onToggleAvailability != null)
                  Switch(
                    value: item.isAvailable,
                    onChanged: (_) => onToggleAvailability!(),
                  ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: item.isExpanded ? _buildInfoPanel() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          Text(
            item.description,
            style: const TextStyle(fontSize: 13.5, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _MandatoryBadge extends StatelessWidget {
  const _MandatoryBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'REQUIRED',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
