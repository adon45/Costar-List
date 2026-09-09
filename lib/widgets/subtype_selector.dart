import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bottom sheet used by the Media Types screen to ask which sub-type of an
/// assignment (e.g. Industrial/Office/Retail/Multifamily) the user wants,
/// before navigating to the checklist screen.
Future<String?> showSubtypeSelector(
  BuildContext context, {
  required String title,
  required List<String> subtypes,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            for (final subtype in subtypes)
              ListTile(
                title: Text(subtype),
                trailing: const Icon(Icons.chevron_right, color: AppColors.accent),
                onTap: () => Navigator.of(context).pop(subtype),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
