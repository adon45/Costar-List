import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/checklist_data.dart';
import '../models/media_type.dart';
import '../models/room_bucket.dart';
import '../theme/app_theme.dart';
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
        title: provider.isApartments
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CounterWidget(
                    captured: provider.captured,
                    totalNeeded: provider.totalNeeded,
                  ),
                  const SizedBox(width: 8),
                  _MetricPill(
                    label: 'Matterport',
                    value:
                        '${provider.apartmentMatterportCaptured}/${provider.apartmentMatterportTarget}',
                    isComplete: provider.apartmentMatterportTarget > 0 &&
                        provider.apartmentMatterportCaptured >=
                            provider.apartmentMatterportTarget,
                    onTap: () => _showApartmentMatterportPicker(context, provider),
                  ),
                  const SizedBox(width: 8),
                  _MetricPill(
                    label: 'Splat',
                    value:
                        '${provider.apartmentSplatCaptured}/${provider.apartmentSplatTarget}',
                    isComplete: provider.apartmentSplatCaptured >=
                        provider.apartmentSplatTarget,
                    onTap: () => provider.setApartmentSplatCount(
                      provider.apartmentSplatCaptured >= 1 ? 0 : 1,
                    ),
                  ),
                ],
              )
            : CounterWidget(
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
                : provider.isApartments
                    ? _buildApartmentsChecklist(provider)
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

  Widget _buildApartmentsChecklist(ChecklistProvider provider) {
    final stillItems = provider.mainList
        .where((item) =>
            item.id != 'matterport_tour' &&
          item.id != 'splat')
        .toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...provider.apartmentMatterports.asMap().entries.map((entry) {
                final index = entry.key;
                final matterport = entry.value;
                return ChoiceChip(
                  label: Text('Matterport ${index + 1}'),
                  selected: matterport.isCompleted,
                  selectedColor: AppColors.accent,
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (_) => provider.toggleApartmentMatterport(index),
                );
              }),
              if (provider.apartmentSplats.isNotEmpty)
                ChoiceChip(
                  label: const Text('Splat'),
                  selected: provider.apartmentSplats.first.isCompleted,
                  selectedColor: AppColors.accent,
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (_) => provider.toggleApartmentSplat(),
                ),
            ],
          ),
        ),
        ...stillItems.map((item) {
          if (item.id == 'units') {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Card(
                child: ExpansionTile(
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  initiallyExpanded: item.isExpanded,
                  onExpansionChanged: (_) => provider.toggleExpanded(item.id),
                  children: [
                    ...provider.apartmentUnits.expand((unit) {
                      final rooms = provider.apartmentUnitRooms[unit.id] ?? const <RoomBucket>[];
                      final standardRooms = rooms
                          .where((room) =>
                              room.name != 'Detail Shots' && room.name != 'View')
                          .toList();
                      final trailingRooms = rooms
                          .where((room) =>
                              room.name == 'Detail Shots' || room.name == 'View')
                          .toList();

                      return [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                          child: Card(
                            child: ExpansionTile(
                              title: Text(
                                unit.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: provider.canRemoveApartmentUnit(unit.id)
                                        ? () => provider.removeApartmentUnit(unit.id)
                                        : null,
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Remove Unit'),
                                  ),
                                ),
                                ...standardRooms.map(
                                  (room) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: RoomBucketTile(
                                      bucket: room,
                                      onAddPhoto: () => provider.addApartmentUnitPhoto(room.id),
                                      onRemovePhoto: () => provider.removeApartmentUnitPhoto(room.id),
                                      onToggleCompleted: () => provider.toggleApartmentUnitCompleted(room.id),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => provider.addApartmentUnitRoom(unit.id, 'Bedroom'),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Bedroom'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => provider.addApartmentUnitRoom(unit.id, 'Bathroom'),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Bathroom'),
                                    ),
                                  ],
                                ),
                                ...trailingRooms.map(
                                  (room) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: RoomBucketTile(
                                      bucket: room,
                                      onAddPhoto: () => provider.addApartmentUnitPhoto(room.id),
                                      onRemovePhoto: () => provider.removeApartmentUnitPhoto(room.id),
                                      onToggleCompleted: () => provider.toggleApartmentUnitCompleted(room.id),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ];
                    }),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: provider.addApartmentUnit,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Unit'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (item.id == 'amenities') {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Card(
                child: ExpansionTile(
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  initiallyExpanded: item.isExpanded,
                  onExpansionChanged: (_) => provider.toggleExpanded(item.id),
                  children: [
                    for (final amenity in provider.apartmentAmenities)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: RoomBucketTile(
                          bucket: amenity,
                          onAddPhoto: () => provider.addApartmentAmenityPhoto(amenity.id),
                          onRemovePhoto: () => provider.removeApartmentAmenityPhoto(amenity.id),
                          onToggleCompleted: () => provider.toggleApartmentAmenityCompleted(amenity.id),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: DeliverableTile(
              item: item,
              onToggleCompleted: () => provider.toggleCompletion(item.id),
              onToggleExpanded: () => provider.toggleExpanded(item.id),
            ),
          );
        }),
      ],
    );
  }

  static int _apartmentMatterportLimit(String? subtype) {
    switch (subtype) {
      case 'Gold':
        return 2;
      case 'Platinum':
        return 4;
      case 'Diamond':
      case 'Diamond Plus':
        return 6;
      case 'Diamond Spotlight':
        return 12;
      default:
        return 0;
    }
  }

  static bool _apartmentHasVideo(String? subtype) {
    return switch (subtype) {
      'Diamond' || 'Diamond Plus' || 'Diamond Spotlight' => true,
      _ => false,
    };
  }

  static int _apartmentStillImageTarget(String? subtype) {
    return switch (subtype) {
      'Gold' => 20,
      'Platinum' => 30,
      'Diamond' || 'Diamond Plus' => 30,
      'Diamond Spotlight' => 60,
      _ => 0,
    };
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

  Future<void> _showApartmentMatterportPicker(
    BuildContext context,
    ChecklistProvider provider,
  ) async {
    final max = provider.apartmentMatterportTargetLimit;
    var target = provider.apartmentMatterportTarget;
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Matterport target'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$target / $max'),
              Slider(
                value: target.toDouble(),
                min: 0,
                max: max.toDouble(),
                divisions: max == 0 ? 1 : max,
                label: '$target',
                onChanged: (value) => setState(() => target = value.round()),
              ),
              Text('Allowed range: 0–$max'),
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
    if (selected != null) provider.setApartmentMatterportTarget(selected);
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

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 142,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final bool isComplete;
  final VoidCallback onTap;

  const _MetricPill({
    required this.label,
    required this.value,
    this.isComplete = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isComplete ? AppColors.accent : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Text(
          '$label $value',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}
