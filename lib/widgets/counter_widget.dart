import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small pill showing "Captured / Total Needed" in the AppBar title area.
class CounterWidget extends StatelessWidget {
  final int captured;
  final int totalNeeded;

  const CounterWidget({
    super.key,
    required this.captured,
    required this.totalNeeded,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = totalNeeded > 0 && captured >= totalNeeded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isComplete
            ? AppColors.accent
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$captured / $totalNeeded',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
