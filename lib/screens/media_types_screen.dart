import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/media_type.dart';
import '../state/checklist_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/subtype_selector.dart';
import 'checklist_screen.dart';

/// The first screen of the app: a list of every assignment type. Types
/// without a defined checklist render faded, labeled "Coming Soon", and
/// are non-interactive.
class MediaTypesScreen extends StatelessWidget {
  const MediaTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media Types')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mediaTypeConfigs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final config = mediaTypeConfigs[index];
          return _MediaTypeTile(config: config);
        },
      ),
    );
  }
}

class _MediaTypeTile extends StatelessWidget {
  final MediaTypeConfig config;

  const _MediaTypeTile({required this.config});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tile = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              config.comingSoon ? Icons.hourglass_top : Icons.checklist,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ).copyWith(color: colorScheme.onSurface),
                ),
                if (config.comingSoon)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Coming Soon',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!config.comingSoon)
            const Icon(Icons.chevron_right, color: AppColors.accent),
        ],
      ),
    );

    if (config.comingSoon) {
      return Opacity(opacity: 0.45, child: tile);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _open(context),
      child: tile,
    );
  }

  Future<void> _open(BuildContext context) async {
    String? subtype;
    if (config.hasSubtypes) {
      subtype = await showSubtypeSelector(
        context,
        title: config.title,
        subtypes: config.subtypes,
      );
      if (subtype == null) return; // user dismissed the sheet
    }

    if (!context.mounted) return;
    final provider = context.read<ChecklistProvider>();
    await provider.loadAssignment(config.type, subtype);

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChecklistScreen()),
    );
  }
}
