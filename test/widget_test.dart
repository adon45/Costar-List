import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:media_checklist/data/checklist_data.dart';
import 'package:media_checklist/models/media_type.dart';
import 'package:media_checklist/screens/media_types_screen.dart';
import 'package:media_checklist/state/checklist_provider.dart';
import 'package:media_checklist/theme/app_theme.dart';

void main() {
  test('Homes Platinum modes contain the requested photo totals', () {
    expect(getChecklist(MediaType.homesPlatinum, '1–2,500 sqft'), hasLength(20));
    expect(
      getChecklist(MediaType.homesPlatinum, '2,500–6,000 sqft'),
      hasLength(30),
    );
    expect(getChecklist(MediaType.homesPlatinum, '6,000+ sqft'), hasLength(35));
    expect(
      getChecklist(MediaType.homesPlatinum, '6,000+ sqft')
          .every((item) => item.isToggleable && item.description.isEmpty),
      isTrue,
    );
  });

  test('media type configuration contains all requested assignments', () {
    expect(
      mediaTypeConfigs.map((config) => config.title),
      containsAll([
        'Photo Assignments',
        'Apartments Gold Media Shoot',
        'Apartments Platinum Media Shoot',
        'Apartments Diamond Media Shoot',
        'Homes Platinum Shoot',
        'Homes Matterport Shoot',
        'Status Verifications',
      ]),
    );
  });

  testWidgets('media types screen lists defined and coming soon assignments',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ChecklistProvider(),
        child: MaterialApp(
          theme: AppTheme.theme,
          home: const MediaTypesScreen(),
        ),
      ),
    );

    expect(find.text('Photo Assignments'), findsOneWidget);
    expect(find.text('Apartments Gold Media Shoot'), findsOneWidget);
    expect(find.text('Apartments Platinum Media Shoot'), findsOneWidget);
    expect(find.text('Apartments Diamond Media Shoot'), findsOneWidget);
    expect(find.text('Homes Platinum Shoot'), findsOneWidget);
    expect(find.text('Homes Matterport Shoot'), findsOneWidget);
    expect(find.text('Coming Soon'), findsNWidgets(4));
  });
}
