import 'package:flutter/material.dart';

import '../models/room_bucket.dart';

class RoomBucketTile extends StatelessWidget {
  final RoomBucket bucket;
  final VoidCallback onAddPhoto;
  final VoidCallback onRemovePhoto;
  final VoidCallback onToggleCompleted;
  final VoidCallback? onRemoveBucket;

  const RoomBucketTile({
    super.key,
    required this.bucket,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onToggleCompleted,
    this.onRemoveBucket,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: bucket.isCompleted ? 0.55 : 1,
      child: Card(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bucket.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15.5,
                          ),
                        ),
                        Text(
                          'Photos: ${bucket.photoCount}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: bucket.isCompleted,
                    onChanged: (_) => onToggleCompleted(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: bucket.isCompleted ? null : onRemovePhoto,
                    icon: const Icon(Icons.remove),
                    tooltip: 'Remove photo',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: bucket.isCompleted ? null : onAddPhoto,
                    icon: const Icon(Icons.add),
                    tooltip: 'Add photo',
                    visualDensity: VisualDensity.compact,
                  ),
                  if (onRemoveBucket != null) ...[
                    const Spacer(),
                    IconButton(
                      onPressed: onRemoveBucket,
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remove room',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
