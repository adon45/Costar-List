import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/checklist_screen.dart';
import 'screens/media_types_screen.dart';
import 'screens/welcome_screen.dart';
import 'state/checklist_provider.dart';
import 'state/theme_provider.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MediaChecklistApp());
}

class MediaChecklistApp extends StatelessWidget {
  const MediaChecklistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChecklistProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
      ],
      child: Builder(
        builder: (context) => MaterialApp(
          title: 'Media Checklist',
          debugShowCheckedModeBanner: false,
          theme: context.watch<ThemeProvider>().isDarkMode
              ? AppTheme.darkTheme
              : AppTheme.theme,
          home: WelcomeScreen(
            onContinue: (context) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const _StartupGate()),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Decides which screen to show first: if the user had an assignment open
/// last time, restore straight into its checklist screen; otherwise show
/// the Media Types screen.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  late final Future<bool> _restoreFuture;

  @override
  void initState() {
    super.initState();
    _restoreFuture = context.read<ChecklistProvider>().init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _restoreFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        final restored = snapshot.data ?? false;
        return restored ? const ChecklistScreen() : const MediaTypesScreen();
      },
    );
  }
}
