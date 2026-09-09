import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/media_type.dart';
import '../state/checklist_provider.dart';
import '../widgets/counter_widget.dart';
import '../widgets/deliverable_tile.dart';
import '../widgets/menu_drawer.dart';
import '../widgets/unavailable_section.dart';

/// The checklist screen for a single assignment (media type + optional
/// sub-type). Shows the scrollable deliverable list, the counter, the menu
/// drawer to switch assignments, and a reset button.
class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final config = provider.mediaType == null
        ? null
        : configFor(provider.mediaType!);
    final title = config == null
        ? 'Checklist'
        : (provider.subtype != null
            ? '${config.title} — ${provider.subtype}'
            : config.title);

    return Scaffold(
      drawer: const MenuDrawer(),
      appBar: AppBar(
        title: CounterWidget(
          captured: provider.captured,
          totalNeeded: provider.totalNeeded,
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Switch Assignment',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Checklist',
            onPressed: () => _confirmReset(context, provider),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                ...provider.mainList.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: DeliverableTile(
                      item: item,
                      onToggleCompleted: () =>
                          provider.toggleCompletion(item.id),
                      onToggleExpanded: () => provider.toggleExpanded(item.id),
                      onToggleAvailability: item.isAlternativeTile
                          ? null
                          : (item.isToggleable
                              ? () => provider.toggleAvailability(item.id)
                              : null),
                    ),
                  ),
                ),
                UnavailableSection(
                  items: provider.unavailableList,
                  onRestore: provider.toggleAvailability,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    ChecklistProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Checklist?'),
        content: const Text(
          'This clears all completion checks, availability toggles, '
          'alternatives, and expanded info for this assignment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      provider.resetAssignment();
    }
  }
}
