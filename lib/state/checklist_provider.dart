import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/checklist_data.dart';
import '../models/deliverable.dart';
import '../models/media_type.dart';

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

  bool _initialized = false;
  bool get isInitialized => _initialized;

  MediaType? get mediaType => _mediaType;
  String? get subtype => _subtype;

  int get captured =>
      mainList.where((d) => !d.isAlternativeTile && d.isCompleted).length;
  int get totalNeeded => _defs.where((def) {
        final state = _stateFor(def.id);
        return !def.isToggleable || state.isAvailable;
      }).length;

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
    final state = _stateFor(id);
    state.isCompleted = !state.isCompleted;
    _rebuildLists();
    _persist();
    notifyListeners();
  }

  /// Expands/collapses the "More Info" panel for any item id.
  void toggleExpanded(String id) {
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
