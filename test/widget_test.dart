import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:media_checklist/data/checklist_data.dart';
import 'package:media_checklist/main.dart';
import 'package:media_checklist/models/media_type.dart';
import 'package:media_checklist/screens/media_types_screen.dart';
import 'package:media_checklist/state/checklist_provider.dart';
import 'package:media_checklist/theme/app_theme.dart';

void main() {
  testWidgets('app opens on the welcome screen and continues to media types',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MediaChecklistApp());

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Media Types'), findsOneWidget);
  });

  test('Homes Platinum defines the flexible bucket list and photo ranges', () {
    expect(createHomesPlatinumBuckets(), hasLength(12));
    expect(
      createHomesPlatinumBuckets().map((bucket) => bucket.name),
      containsAll([
        'Front Exterior',
        'Entry',
        'Living Room',
        'Dining Room',
        'Kitchen',
        'Family Room',
        'Patio/Deck',
        'Rear Exterior',
        'Primary Bedroom',
        'Primary Bathroom',
        'Detail Captures',
        'Aerial',
      ]),
    );
    expect(homesPlatinumPhotoRange('0–2,000 sqft').minimum, 35);
    expect(homesPlatinumPhotoRange('8,000+ sqft').maximum, 80);
  });

  test('Homes Platinum counts photos and creates dynamic bedrooms', () async {
    final provider = ChecklistProvider();
    await provider.loadAssignment(
      MediaType.homesPlatinum,
      '0–2,000 sqft',
    );

    expect(provider.roomBuckets, hasLength(12));
    expect(provider.requiredTotal, 37);
    provider.addPhoto('front_exterior');
    provider.addPhoto('front_exterior');
    provider.removePhoto('front_exterior');
    provider.addBedroom();
    provider.addBathroom();

    expect(provider.captured, 1);
    expect(provider.dynamicBedrooms.single.name, 'Bedroom 1');
    expect(provider.dynamicBathrooms.single.name, 'Bathroom 1');
    expect(provider.unavailableList, isEmpty);
    provider.removeBedroom('additional_bedroom_1');
    provider.removeBathroom('additional_bathroom_1');
    expect(provider.dynamicBedrooms, isEmpty);
    expect(provider.dynamicBathrooms, isEmpty);
  });

  test('Homes Platinum restores bucket state and dynamic bedrooms', () async {
    SharedPreferences.setMockInitialValues({});
    final firstProvider = ChecklistProvider();
    await firstProvider.init();
    await firstProvider.loadAssignment(
      MediaType.homesPlatinum,
      '4,000–6,000 sqft',
    );
    firstProvider.addPhoto('kitchen');
    firstProvider.toggleBucketCompleted('kitchen');
    firstProvider.toggleBucketExpanded('kitchen');
    firstProvider.addBedroom();
    firstProvider.setRequiredTotal(63);

    final restoredProvider = ChecklistProvider();
    expect(await restoredProvider.init(), isTrue);
    expect(restoredProvider.captured, 1);
    expect(restoredProvider.requiredTotal, 63);
    expect(restoredProvider.dynamicBedrooms.single.name, 'Bedroom 1');
    final kitchen = restoredProvider.roomBuckets
        .firstWhere((bucket) => bucket.id == 'kitchen');
    expect(kitchen.isCompleted, isTrue);
    expect(kitchen.isExpanded, isTrue);
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
