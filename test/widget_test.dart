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
        'Apartments',
        'LoopNet',
        'Homes Platinum Shoot',
        'Status Verifications',
        'Ten-X',
      ]),
    );
    expect(
      configFor(MediaType.apartments).subtypes,
      containsAll(['Gold', 'Platinum', 'Diamond', 'Diamond Plus', 'Diamond Spotlight']),
    );
    expect(
      configFor(MediaType.loopNet).subtypes,
      containsAll(['Gold', 'Platinum', 'Diamond', 'Diamond+', 'Diamond Spotlight']),
    );
    expect(configFor(MediaType.loopNet).comingSoon, isTrue);
    expect(configFor(MediaType.tenX).comingSoon, isTrue);
  });

  test('apartments checklist includes top delivery tiles and still image options', () {
    final checklist = getChecklist(MediaType.apartments, 'Diamond Plus');
    final names = checklist.map((entry) => entry.name).toList();

    expect(names, contains('Matterport Tour'));
    expect(names, contains('Splat'));
    expect(names, contains('Video'));
    expect(names, isNot(contains('Still Images')));
    expect(names, contains('Amenities'));
    expect(names, containsAll([
      'Primary',
      'Lobby',
      'Units',
      'Amenities',
      'Alternate Community Images',
      'Building Entrance',
      'Aerial Context',
      '90° Lookdown',
    ]));
    for (final subtype in ['Diamond', 'Diamond Plus', 'Diamond Spotlight']) {
      final diamondNames = getChecklist(MediaType.apartments, subtype)
          .map((entry) => entry.name)
          .toList();
      expect(
        diamondNames.indexOf('Video'),
        diamondNames.indexOf('Building Entrance') + 1,
      );
    }
  });

  test('loading an apartment subtype populates checklist items', () async {
    final provider = ChecklistProvider();
    await provider.loadAssignment(MediaType.apartments, 'Gold');

    expect(provider.mainList, isNotEmpty);
    expect(provider.mainList.map((item) => item.id), contains('amenities'));
  });

  test('apartment units and matterport tracking tally into lives counts', () async {
    final provider = ChecklistProvider();
    await provider.loadAssignment(MediaType.apartments, 'Platinum');

    expect(provider.apartmentMatterportTarget, 4);
    expect(provider.apartmentMatterportCaptured, 0);
    expect(provider.apartmentAmenities, isNotEmpty);
    provider.setApartmentMatterportTarget(3);
    expect(provider.apartmentMatterportTarget, 3);
    expect(provider.apartmentUnits, isNotEmpty);

    provider.addApartmentUnit();
    expect(provider.apartmentUnits.length, 2);
    final addedUnit = provider.apartmentUnits.last;
    expect(provider.canRemoveApartmentUnit(addedUnit.id), isTrue);
    provider.removeApartmentUnit(addedUnit.id);
    expect(provider.apartmentUnits, hasLength(1));

    provider.addApartmentUnit();
    final workedUnit = provider.apartmentUnits.last;
    final workedRoomId = provider.apartmentUnitRooms[workedUnit.id]!.first.id;
    provider.addApartmentUnitPhoto(workedRoomId);
    expect(provider.canRemoveApartmentUnit(workedUnit.id), isFalse);
    provider.removeApartmentUnit(workedUnit.id);
    expect(provider.apartmentUnits, hasLength(2));

    provider.addApartmentUnit();
    final checkedUnit = provider.apartmentUnits.last;
    final checkedRoomId = provider.apartmentUnitRooms[checkedUnit.id]!.first.id;
    provider.toggleApartmentUnitCompleted(checkedRoomId);
    expect(provider.canRemoveApartmentUnit(checkedUnit.id), isFalse);
    provider.removeApartmentUnit(checkedUnit.id);
    expect(provider.apartmentUnits, hasLength(3));

    provider.apartmentAmenities.first.photoCount++;
    expect(provider.captured, 2);

    final roomId = provider.apartmentUnitRooms.values.first.first.id;
    provider.addApartmentUnitPhoto(roomId);
    expect(provider.captured, 3);
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
    expect(find.text('Apartments'), findsOneWidget);
    expect(find.text('LoopNet'), findsOneWidget);
    expect(find.text('Homes Platinum Shoot'), findsOneWidget);
    expect(find.text('Status Verifications'), findsOneWidget);
    expect(find.text('Ten-X'), findsOneWidget);
    expect(find.text('Coming Soon'), findsNWidgets(2));
  });
}
