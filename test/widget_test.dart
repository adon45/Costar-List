import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:media_checklist/data/checklist_data.dart';
import 'package:media_checklist/models/media_type.dart';
import 'package:media_checklist/screens/media_types_screen.dart';
import 'package:media_checklist/state/checklist_provider.dart';
import 'package:media_checklist/theme/app_theme.dart';

void main() {
  test('Homes Platinum lists rooms and 25 flexible shots', () {
    const subtypes = ['1–2,500 sqft', '2,500–6,000 sqft', '6,000+ sqft'];
    const roomNames = [
      'Front Exterior',
      'Rear Exterior',
      'Patio / Deck',
      'Aerial',
      'Entry',
      'Living Room',
      'Dining Room',
      'Family Room',
      'Kitchen',
      'Bathroom(s)',
      'Primary Bedroom',
      'Primary Bathroom',
      'Second Bedroom',
      'Third Bedroom',
    ];

    for (final subtype in subtypes) {
      final checklist = getChecklist(MediaType.homesPlatinum, subtype);
      expect(checklist, hasLength(25));
      expect(checklist.map((item) => item.name), containsAll(roomNames));
      expect(
        checklist.where((item) => item.name.startsWith('Detail Shot')),
        hasLength(11),
      );
      expect(checklist.where((item) => item.name.startsWith('Alternate')),
          isEmpty);
      expect(checklist.every((item) => !item.hasAlternative), isTrue);
      expect(checklist.every((item) => !item.isMandatory), isTrue);
    }
  });

  test('Homes Platinum replaces unavailable rooms with detail shots', () async {
    final provider = ChecklistProvider();
    await provider.loadAssignment(
      MediaType.homesPlatinum,
      '1–2,500 sqft',
    );

    expect(provider.mainList, hasLength(25));
    provider.toggleAvailability('front_exterior');

    expect(provider.mainList, hasLength(25));
    expect(provider.unavailableList.map((item) => item.name),
        contains('Front Exterior'));
    expect(
      provider.mainList.where((item) => item.name.startsWith('Detail Shot')),
      hasLength(12),
    );
  });

  test('Industrial photo assignments omit loading and garage shots', () {
    final checklist = getChecklist(MediaType.photoAssignments, 'Industrial');

    expect(checklist.map((item) => item.name), isNot(contains('Garages')));
    expect(
      checklist.map((item) => item.name),
      isNot(contains('Loading Ramps / Loading Docks / Drive-in Bays')),
    );
    expect(checklist.map((item) => item.name),
        contains('One-point perspective of loading side'));
    expect(checklist.every((item) => !item.isMandatory), isTrue);
    expect(checklist.every((item) => item.isToggleable), isTrue);
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
