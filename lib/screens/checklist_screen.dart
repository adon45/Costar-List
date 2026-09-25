import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/checklist_data.dart';
import '../models/media_type.dart';
import '../state/checklist_provider.dart';
import '../widgets/counter_widget.dart';
import '../widgets/deliverable_tile.dart';
import '../widgets/menu_drawer.dart';
import '../widgets/room_bucket_tile.dart';
import '../widgets/unavailable_section.dart';

/// The checklist screen for a single assignment (media type + optional
/// sub-type). Shows the scrollable deliverable list, the counter, the menu
/// drawer to switch assignments, and a reset button.
class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();
    final config =
        provider.mediaType == null ? null : configFor(provider.mediaType!);
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
          if (provider.isHomesPlatinum)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Set photo target',
              onPressed: () => _showTargetPicker(context, provider),
            ),
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
            child: provider.isHomesPlatinum
                ? _buildHomesBuckets(context, provider)
                : _buildLegacyChecklist(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyChecklist(ChecklistProvider provider) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        ...provider.mainList.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: DeliverableTile(
              item: item,
              onToggleCompleted: () => provider.toggleCompletion(item.id),
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
    );
  }

  Widget _buildHomesBuckets(
    BuildContext context,
    ChecklistProvider provider,
  ) {
    final buckets = [
      ...provider.roomBuckets.where(
        (bucket) => bucket.name != 'Detail Captures' && bucket.name != 'Aerial',
      ),
    ];
    final detailCaptures = provider.roomBuckets.firstWhere(
      (bucket) => bucket.name == 'Detail Captures',
    );
    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        ...buckets.map((bucket) => _bucketTile(provider, bucket)),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: provider.addBedroom,
            icon: const Icon(Icons.add),
            label: const Text('Add Bedroom'),
          ),
        ),
        ...provider.dynamicBedrooms.map(
          (bucket) => _bucketTile(
            provider,
            bucket,
            onRemove: () => provider.removeBedroom(bucket.id),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: provider.addBathroom,
            icon: const Icon(Icons.add),
            label: const Text('Add Bathroom'),
          ),
        ),
        ...provider.dynamicBathrooms.map(
          (bucket) => _bucketTile(
            provider,
            bucket,
            onRemove: () => provider.removeBathroom(bucket.id),
          ),
        ),
        _bucketTile(provider, detailCaptures),
        if (provider.roomBuckets.isNotEmpty)
          _bucketTile(provider, provider.roomBuckets.last),
      ],
    );
  }

  Widget _bucketTile(
    ChecklistProvider provider,
    dynamic bucket, {
    VoidCallback? onRemove,
  }) {
    return RoomBucketTile(
      bucket: bucket,
      onAddPhoto: () => provider.addPhoto(bucket.id),
      onRemovePhoto: () => provider.removePhoto(bucket.id),
      onToggleCompleted: () => provider.toggleBucketCompleted(bucket.id),
      onRemoveBucket: onRemove,
    );
  }

  Future<void> _showTargetPicker(
    BuildContext context,
    ChecklistProvider provider,
  ) async {
    final range = homesPlatinumPhotoRange(provider.subtype);
    var target = provider.requiredTotal;
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Photo target'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$target photos'),
              Slider(
                value: target.toDouble(),
                min: range.minimum.toDouble(),
                max: range.maximum.toDouble(),
                divisions: range.maximum - range.minimum,
                label: '$target',
                onChanged: (value) => setState(() => target = value.round()),
              ),
              Text('${range.minimum}–${range.maximum} photos allowed'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(target),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (selected != null) provider.setRequiredTotal(selected);
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
