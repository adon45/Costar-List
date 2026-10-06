import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/checklist_data.dart';
import '../models/deliverable.dart';
import '../models/media_type.dart';
import '../models/room_bucket.dart';

/// Key used to remember which assignment (media type + sub-type) the user
/// last had open, so relaunching the app can restore it.
const String _lastAssignmentPrefsKey = 'last_assignment_v1';
const String _stateKeyPrefix = 'checklist_state_v1__';

/// Owns all runtime state for the currently-open checklist: the resolved
/// main list, the unavailable list, the counter, and persistence to disk.
///
/// One [ChecklistProvider] instance is shared app-wide; switching
/// assignments calls [loadAssignment] which swaps out the in-memory state
/// after saving whatever was previously open.
class ChecklistProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  MediaType? _mediaType;
  String? _subtype;
  List<DeliverableDef> _defs = const [];
  final Map<String, DeliverableState> _states = {};

  List<DeliverableItem> mainList = [];
  List<DeliverableItem> unavailableList = [];
  List<RoomBucket> roomBuckets = [];
  List<RoomBucket> dynamicBedrooms = [];
  List<RoomBucket> dynamicBathrooms = [];
  List<RoomBucket> apartmentUnits = [];
  List<RoomBucket> apartmentMatterports = [];
  List<RoomBucket> apartmentSplats = [];
  List<RoomBucket> apartmentAmenities = [];
  final Map<String, List<RoomBucket>> apartmentUnitRooms = {};
  int apartmentMatterportTarget = 0;
  int capturedTotal = 0;
  int requiredTotal = 0;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  MediaType? get mediaType => _mediaType;
  String? get subtype => _subtype;

  bool get isHomesPlatinum => _mediaType == MediaType.homesPlatinum;
  bool get isApartments => _mediaType == MediaType.apartments;

  int get captured => isHomesPlatinum
      ? capturedTotal
      : isApartments
          ? _apartmentCaptured
          : mainList.where((d) => d.isCompleted).length;
  int get totalNeeded => isHomesPlatinum
      ? requiredTotal
      : isApartments
          ? _apartmentRequiredTotal
          : mainList.length;
  int get apartmentMatterportTargetLimit => switch (_subtype) {
        'Gold' => 2,
        'Platinum' => 4,
        'Diamond' || 'Diamond Plus' => 6,
        'Diamond Spotlight' => 12,
        _ => 0,
      };
  int get apartmentSplatTarget => 1;
  int get apartmentMatterportCaptured =>
      apartmentMatterports.where((item) => item.isCompleted).length;
  int get apartmentSplatCaptured =>
      apartmentSplats.where((item) => item.isCompleted).length;
  int get _apartmentCaptured {
    final staticCount = _defs
        .where((def) =>
            !{'matterport_tour', 'splat', 'video', 'still_images'}.contains(def.id))
        .where((def) => _stateFor(def.id).isCompleted)
        .length;
    final amenityCount = apartmentAmenities.fold(
      0,
      (sum, room) => sum + room.photoCount,
    );
    final unitCount = apartmentUnitRooms.values.fold(
      0,
      (sum, rooms) => sum +
          rooms.fold(0, (roomSum, room) => roomSum + room.photoCount),
    );
    return staticCount + amenityCount + unitCount;
  }

  int get _apartmentRequiredTotal {
    switch (_subtype) {
      case 'Gold':
        return 20;
      case 'Platinum':
        return 30;
      case 'Diamond':
      case 'Diamond Plus':
        return 30;
      case 'Diamond Spotlight':
        return 60;
      default:
        return 0;
    }
  }

  /// Call once at app start. Loads shared preferences and, if a previous
  /// assignment was open, restores it. Returns true if an assignment was
  /// restored (so the UI can navigate straight to the checklist screen).
  Future<bool> init() async {
    _prefs = await SharedPreferences.getInstance();
    final last = _prefs?.getString(_lastAssignmentPrefsKey);
    _initialized = true;
    if (last != null) {
      try {
        final decoded = jsonDecode(last) as Map<String, dynamic>;
        final typeName = decoded['type'] as String?;
        final subtype = decoded['subtype'] as String?;
        final type = MediaType.values.firstWhere(
          (t) => t.name == typeName,
          orElse: () => MediaType.photoAssignments,
        );
        final config = configFor(type);
        if (!config.comingSoon &&
            (config.hasSubtypes ? subtype != null : true)) {
          await loadAssignment(type, subtype);
          return true;
        }
      } catch (_) {
        // Ignore malformed/legacy stored data and fall back to the
        // Media Types screen.
      }
    }
    return false;
  }

  /// Loads (or switches to) a given assignment, merging any previously
  /// persisted per-item state onto the static checklist definition.
  Future<void> loadAssignment(MediaType type, String? subtype) async {
    _mediaType = type;
    _subtype = subtype;
    _defs = getChecklist(type, subtype);
    _states.clear();

    roomBuckets = [];
    dynamicBedrooms = [];
    dynamicBathrooms = [];
    apartmentUnits = [];
    apartmentMatterports = [];
    apartmentSplats = [];
    apartmentAmenities = [];
    apartmentUnitRooms.clear();
    apartmentMatterportTarget = 0;
    capturedTotal = 0;
    requiredTotal = 0;

    if (type == MediaType.apartments) {
      apartmentMatterportTarget = apartmentMatterportTargetLimit;
      apartmentMatterports = List.generate(
        apartmentMatterportTarget,
        (index) => RoomBucket(
          id: 'apartment_matterport_${index + 1}',
          name: 'Matterport ${index + 1}',
        ),
      );
      apartmentSplats = [RoomBucket(id: 'apartment_splat', name: 'Splat')];
      apartmentAmenities = [
        RoomBucket(id: 'apartment_amenity_fitness_center', name: 'Fitness Center'),
        RoomBucket(id: 'apartment_amenity_pool', name: 'Pool'),
        RoomBucket(id: 'apartment_amenity_clubhouse', name: 'Clubhouse'),
        RoomBucket(
          id: 'apartment_amenity_other_interior',
          name: 'Other Interior Amenities',
        ),
        RoomBucket(
          id: 'apartment_amenity_other_exterior',
          name: 'Other Exterior Amenities',
        ),
      ];
      addApartmentUnit();
      _rebuildLists();
      await _rememberLastAssignment();
      notifyListeners();
      return;
    }

    if (type == MediaType.homesPlatinum) {
      await _loadHomesPlatinum();
      await _rememberLastAssignment();
      notifyListeners();
      return;
    }

    final raw = _prefs?.getString(_storageKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((id, value) {
          _states[id] =
              DeliverableState.fromJson(value as Map<String, dynamic>);
        });
      } catch (_) {
        // Corrupt data for this assignment; start fresh.
      }
    }

    _rebuildLists();
    await _rememberLastAssignment();
    notifyListeners();
  }

  String get _storageKey =>
      '$_stateKeyPrefix${assignmentKey(_mediaType ?? MediaType.photoAssignments, _subtype)}';

  DeliverableState _stateFor(String id) =>
      _states.putIfAbsent(id, () => DeliverableState());

  Future<void> _loadHomesPlatinum() async {
    final range = homesPlatinumPhotoRange(_subtype);
    requiredTotal = range.midpoint;
    roomBuckets = createHomesPlatinumBuckets();

    final raw = _prefs?.getString(_storageKey);
    if (raw == null) return;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      capturedTotal = decoded['capturedTotal'] as int? ?? 0;
      final savedRequired = decoded['requiredTotal'] as int?;
      if (savedRequired != null &&
          savedRequired >= range.minimum &&
          savedRequired <= range.maximum) {
        requiredTotal = savedRequired;
      }

      final savedBuckets = decoded['buckets'] as Map<String, dynamic>? ?? {};
      for (var index = 0; index < roomBuckets.length; index++) {
        final bucket = roomBuckets[index];
        final saved = savedBuckets[bucket.id];
        if (saved is Map<String, dynamic>) {
          roomBuckets[index] = RoomBucket(
            id: bucket.id,
            name: bucket.name,
            photoCount: saved['photoCount'] as int? ?? 0,
            isCompleted: saved['isCompleted'] as bool? ?? false,
            isExpanded: saved['isExpanded'] as bool? ?? false,
          );
        }
      }

      final savedBedrooms = decoded['dynamicBedrooms'] as List<dynamic>? ?? [];
      dynamicBedrooms = savedBedrooms
          .whereType<Map<String, dynamic>>()
          .map(RoomBucket.fromJson)
          .toList();
      final savedBathrooms =
          decoded['dynamicBathrooms'] as List<dynamic>? ?? [];
      dynamicBathrooms = savedBathrooms
          .whereType<Map<String, dynamic>>()
          .map(RoomBucket.fromJson)
          .toList();
      _normalizeHomesCapturedTotal();
    } catch (_) {
      capturedTotal = 0;
    }
  }

  void _normalizeHomesCapturedTotal() {
    capturedTotal = [
      ...roomBuckets,
      ...dynamicBedrooms,
      ...dynamicBathrooms,
    ].fold(0, (total, bucket) => total + bucket.photoCount);
  }

  RoomBucket? _homesBucket(String id) {
    for (final bucket in [
      ...roomBuckets,
      ...dynamicBedrooms,
      ...dynamicBathrooms,
    ]) {
      if (bucket.id == id) return bucket;
    }
    return null;
  }

  void addPhoto(String id) {
    if (!isHomesPlatinum) return;
    final bucket = _homesBucket(id);
    if (bucket == null) return;
    bucket.photoCount++;
    capturedTotal++;
    _persistHomesPlatinum();
    notifyListeners();
  }

  void removePhoto(String id) {
    if (!isHomesPlatinum) return;
    final bucket = _homesBucket(id);
    if (bucket == null || bucket.photoCount == 0) return;
    bucket.photoCount--;
    capturedTotal--;
    _persistHomesPlatinum();
    notifyListeners();
  }

  void toggleBucketCompleted(String id) {
    if (!isHomesPlatinum) return;
    final bucket = _homesBucket(id);
    if (bucket == null) return;
    bucket.isCompleted = !bucket.isCompleted;
    _persistHomesPlatinum();
    notifyListeners();
  }

  void toggleBucketExpanded(String id) {
    if (!isHomesPlatinum) return;
    final bucket = _homesBucket(id);
    if (bucket == null) return;
    bucket.isExpanded = !bucket.isExpanded;
    _persistHomesPlatinum();
    notifyListeners();
  }

  void addBedroom() {
    if (!isHomesPlatinum) return;
    final number = dynamicBedrooms.length + 1;
    dynamicBedrooms.add(
      RoomBucket(
        id: 'additional_bedroom_$number',
        name: 'Bedroom $number',
      ),
    );
    _persistHomesPlatinum();
    notifyListeners();
  }

  void removeBedroom(String id) {
    if (!isHomesPlatinum) return;
    dynamicBedrooms.removeWhere((bucket) => bucket.id == id);
    _persistHomesPlatinum();
    notifyListeners();
  }

  void addBathroom() {
    if (!isHomesPlatinum) return;
    final number = dynamicBathrooms.length + 1;
    dynamicBathrooms.add(
      RoomBucket(id: 'additional_bathroom_$number', name: 'Bathroom $number'),
    );
    _persistHomesPlatinum();
    notifyListeners();
  }

  void removeBathroom(String id) {
    if (!isHomesPlatinum) return;
    dynamicBathrooms.removeWhere((bucket) => bucket.id == id);
    _persistHomesPlatinum();
    notifyListeners();
  }

  void setRequiredTotal(int value) {
    if (!isHomesPlatinum) return;
    final range = homesPlatinumPhotoRange(_subtype);
    if (value < range.minimum || value > range.maximum) return;
    requiredTotal = value;
    _persistHomesPlatinum();
    notifyListeners();
  }

  List<RoomBucket> _defaultApartmentUnitRooms(String unitId) => [
        RoomBucket(id: '${unitId}_kitchen', name: 'Kitchen'),
        RoomBucket(id: '${unitId}_dining_room', name: 'Dining Room'),
        RoomBucket(id: '${unitId}_living_room', name: 'Living Room'),
        RoomBucket(id: '${unitId}_bedroom_1', name: 'Bedroom 1'),
        RoomBucket(id: '${unitId}_bathroom_1', name: 'Bathroom 1'),
        RoomBucket(id: '${unitId}_detail_shots', name: 'Detail Shots'),
        RoomBucket(id: '${unitId}_view', name: 'View'),
      ];

  RoomBucket? _findApartmentRoom(String id) {
    for (final rooms in apartmentUnitRooms.values) {
      for (final room in rooms) {
        if (room.id == id) return room;
      }
    }
    for (final amenity in apartmentAmenities) {
      if (amenity.id == id) return amenity;
    }
    return null;
  }

  void addApartmentAmenityPhoto(String id) {
    if (!isApartments) return;
    final amenity = apartmentAmenities.firstWhere(
      (item) => item.id == id,
      orElse: () => RoomBucket(id: id, name: 'Amenity'),
    );
    if (apartmentAmenities.every((item) => item.id != id)) return;
    amenity.photoCount++;
    notifyListeners();
  }

  void removeApartmentAmenityPhoto(String id) {
    if (!isApartments) return;
    final amenity = apartmentAmenities.firstWhere(
      (item) => item.id == id,
      orElse: () => RoomBucket(id: id, name: 'Amenity'),
    );
    if (apartmentAmenities.every((item) => item.id != id)) return;
    if (amenity.photoCount == 0) return;
    amenity.photoCount--;
    notifyListeners();
  }

  void toggleApartmentAmenityCompleted(String id) {
    if (!isApartments) return;
    final amenity = apartmentAmenities.firstWhere(
      (item) => item.id == id,
      orElse: () => RoomBucket(id: id, name: 'Amenity'),
    );
    if (apartmentAmenities.every((item) => item.id != id)) return;
    amenity.isCompleted = !amenity.isCompleted;
    notifyListeners();
  }

  void addApartmentUnit() {
    if (!isApartments) return;
    var number = 1;
    while (apartmentUnits.any((unit) => unit.id == 'apartment_unit_$number')) {
      number++;
    }
    final id = 'apartment_unit_$number';
    apartmentUnits.add(RoomBucket(id: id, name: 'Unit $number'));
    apartmentUnitRooms[id] = _defaultApartmentUnitRooms(id);
    notifyListeners();
  }

  bool canRemoveApartmentUnit(String id) {
    final rooms = apartmentUnitRooms[id];
    return isApartments &&
        apartmentUnits.any((unit) => unit.id == id) &&
        rooms != null &&
        rooms.every((room) => room.photoCount == 0 && !room.isCompleted);
  }

  void removeApartmentUnit(String id) {
    if (!canRemoveApartmentUnit(id)) return;
    apartmentUnits.removeWhere((bucket) => bucket.id == id);
    apartmentUnitRooms.remove(id);
    notifyListeners();
  }

  void addApartmentUnitRoom(String unitId, String roomKind) {
    if (!isApartments) return;
    final rooms = apartmentUnitRooms.putIfAbsent(
      unitId,
      () => _defaultApartmentUnitRooms(unitId),
    );
    final count = rooms.where((room) => room.name.startsWith(roomKind)).length + 1;
    rooms.add(RoomBucket(id: '${unitId}_${roomKind.toLowerCase()}_$count', name: '$roomKind $count'));
    notifyListeners();
  }

  void addApartmentUnitPhoto(String id) {
    if (!isApartments) return;
    final room = _findApartmentRoom(id);
    if (room == null) return;
    room.photoCount++;
    notifyListeners();
  }

  void removeApartmentUnitPhoto(String id) {
    if (!isApartments) return;
    final room = _findApartmentRoom(id);
    if (room == null || room.photoCount == 0) return;
    room.photoCount--;
    notifyListeners();
  }

  void toggleApartmentUnitCompleted(String id) {
    if (!isApartments) return;
    final room = _findApartmentRoom(id);
    if (room == null) return;
    room.isCompleted = !room.isCompleted;
    notifyListeners();
  }

  void toggleApartmentMatterport(int index) {
    if (!isApartments || index < 0 || index >= apartmentMatterports.length) return;
    apartmentMatterports[index].isCompleted =
        !apartmentMatterports[index].isCompleted;
    notifyListeners();
  }

  void toggleApartmentSplat() {
    if (!isApartments || apartmentSplats.isEmpty) return;
    apartmentSplats.first.isCompleted = !apartmentSplats.first.isCompleted;
    notifyListeners();
  }

  void setApartmentMatterportTarget(int value) {
    if (!isApartments) return;
    final max = apartmentMatterportTargetLimit;
    if (value < 0 || value > max) return;
    apartmentMatterportTarget = value;
    apartmentMatterports = List.generate(
      value,
      (index) => RoomBucket(
        id: 'apartment_matterport_${index + 1}',
        name: 'Matterport ${index + 1}',
        isCompleted: index < apartmentMatterports.length && apartmentMatterports[index].isCompleted,
      ),
    );
    notifyListeners();
  }

  void setApartmentSplatCount(int value) {
    if (!isApartments) return;
    apartmentSplats = [
      RoomBucket(
        id: 'apartment_splat',
        name: 'Splat',
        isCompleted: value > 0,
      )
    ];
    notifyListeners();
  }

  void _rebuildLists() {
    final main = <DeliverableItem>[];
    final unavailable = <DeliverableItem>[];

    for (final def in _defs) {
      final state = _stateFor(def.id);
      final isHidden = def.isToggleable && !state.isAvailable;

      if (isHidden) {
        unavailable.add(DeliverableItem.original(def, state));
        if (def.hasAlternative) {
          final altId = alternativeIdFor(def.id);
          final altState = _stateFor(altId);
          main.add(DeliverableItem.alternative(def, altState));
        }
      } else {
        main.add(DeliverableItem.original(def, state));
      }
    }

    mainList = main;
    unavailableList = unavailable;
  }

  /// Toggles the completion checkbox for any item id (original or
  /// alternative tile).
  void toggleCompletion(String id) {
    if (isHomesPlatinum) {
      toggleBucketCompleted(id);
      return;
    }
    final state = _stateFor(id);
    state.isCompleted = !state.isCompleted;
    _rebuildLists();
    _persist();
    notifyListeners();
  }

  /// Expands/collapses the "More Info" panel for any item id.
  void toggleExpanded(String id) {
    if (isHomesPlatinum) {
      toggleBucketExpanded(id);
      return;
    }
    final state = _stateFor(id);
    state.isExpanded = !state.isExpanded;
    _rebuildLists();
    _persist();
    notifyListeners();
  }

  /// Toggles a deliverable's availability. Only valid for original
  /// (non-alternative) ids whose definition is toggleable. Turning
  /// availability back on clears any spawned alternative tile's state.
  void toggleAvailability(String id) {
    if (isHomesPlatinum) return;
    final def = _defs.firstWhere((d) => d.id == id, orElse: () => _defs.first);
    if (!def.isToggleable) return;

    final state = _stateFor(id);
    state.isAvailable = !state.isAvailable;

    if (state.isAvailable) {
      // Returning to the main list: drop any alternative tile entirely.
      _states.remove(alternativeIdFor(id));
    }

    _rebuildLists();
    _persist();
    notifyListeners();
  }

  /// Resets the currently-open assignment back to its default state:
  /// nothing completed, everything available, nothing expanded, and no
  /// alternative tiles.
  void resetAssignment() {
    if (isHomesPlatinum) {
      roomBuckets = createHomesPlatinumBuckets();
      dynamicBedrooms = [];
      dynamicBathrooms = [];
      capturedTotal = 0;
      requiredTotal = homesPlatinumPhotoRange(_subtype).midpoint;
      _persistHomesPlatinum();
      notifyListeners();
      return;
    }
    if (isApartments) {
      apartmentUnits = [];
      apartmentMatterports = List.generate(
        apartmentMatterportTargetLimit,
        (index) => RoomBucket(
          id: 'apartment_matterport_${index + 1}',
          name: 'Matterport ${index + 1}',
        ),
      );
      apartmentSplats = [RoomBucket(id: 'apartment_splat', name: 'Splat')];
      apartmentUnitRooms.clear();
      addApartmentUnit();
      _states.clear();
      _rebuildLists();
      _persist();
      notifyListeners();
      return;
    }
    _states.clear();
    _rebuildLists();
    _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final encoded = jsonEncode(
      _states.map((id, state) => MapEntry(id, state.toJson())),
    );
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> _persistHomesPlatinum() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final buckets = <String, dynamic>{
      for (final bucket in roomBuckets) bucket.id: bucket.toJson(),
    };
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'capturedTotal': capturedTotal,
        'requiredTotal': requiredTotal,
        'buckets': buckets,
        'dynamicBedrooms':
            dynamicBedrooms.map((bucket) => bucket.toJson()).toList(),
        'dynamicBathrooms':
            dynamicBathrooms.map((bucket) => bucket.toJson()).toList(),
      }),
    );
  }

  Future<void> _rememberLastAssignment() async {
    final prefs = _prefs;
    if (prefs == null || _mediaType == null) return;
    final encoded = jsonEncode({
      'type': _mediaType!.name,
      'subtype': _subtype,
    });
    await prefs.setString(_lastAssignmentPrefsKey, encoded);
  }
}
