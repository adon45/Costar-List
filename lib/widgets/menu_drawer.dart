import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/media_type.dart';
import '../screens/checklist_screen.dart';
import '../screens/settings_screen.dart';
import '../state/checklist_provider.dart';
import '../theme/app_theme.dart';

/// Drawer opened from the top-left menu button on the checklist screen.
/// Lists every media type (with sub-types where relevant) so the user can
/// jump straight to a different assignment.
class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              color: AppColors.primary,
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Switch Assignment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    tooltip: 'Settings',
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            for (final config in mediaTypeConfigs)
              if (!config.comingSoon) ...[
                if (config.hasSubtypes)
                  ExpansionTile(
                    title: Text(
                      config.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    initiallyExpanded: provider.mediaType == config.type,
                    children: [
                      for (final sub in config.subtypes)
                        ListTile(
                          contentPadding: const EdgeInsets.only(
                            left: 32,
                            right: 16,
                          ),
                          title: Text(sub),
                          selected: provider.mediaType == config.type &&
                              provider.subtype == sub,
                          selectedColor: AppColors.accent,
                          onTap: () => _select(context, config.type, sub),
                        ),
                    ],
                  )
                else
                  ListTile(
                    title: Text(
                      config.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    selected: provider.mediaType == config.type,
                    selectedColor: AppColors.accent,
                    onTap: () => _select(context, config.type, null),
                  ),
              ] else
                Opacity(
                  opacity: 0.45,
                  child: ListTile(
                    enabled: false,
                    title: Text(config.title),
                    subtitle: const Text('Coming Soon'),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(
    BuildContext context,
    MediaType type,
    String? subtype,
  ) async {
    final navigator = Navigator.of(context);
    final provider = context.read<ChecklistProvider>();
    navigator.pop(); // close the drawer first
    await provider.loadAssignment(type, subtype);
    if (!context.mounted) return;
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const ChecklistScreen()),
    );
  }
}
