import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/theme_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static final _suggestionUri = Uri.parse(
    'https://forms.cloud.microsoft/r/MKxZb45eDR',
  );

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.isDarkMode,
            activeThumbColor: AppColors.accent,
            onChanged: themeProvider.setDarkMode,
          ),
          ListTile(
            title: const Text('Suggest changes'),
            trailing: IconButton(
              icon: const Icon(Icons.link),
              tooltip: 'Open Suggest changes',
              onPressed: () => launchUrl(
                _suggestionUri,
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
