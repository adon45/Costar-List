/// The immutable, static definition of a single deliverable within a
/// checklist. This never changes at runtime -- all mutable state (checked,
/// available, expanded) lives separately in [DeliverableState] so it can be
/// persisted and merged back onto these definitions.
class DeliverableDef {
  /// Unique id within a single checklist (e.g. "primary", "alternate_2").
  final String id;
  final String name;
  final String description;
  final String? exampleImage;
  final bool isMandatory;

  /// Whether this item can be toggled off into the Unavailable section.
  final bool isToggleable;

  /// Whether toggling this item off should spawn an "Alternative" tile
  /// in the main list.
  final bool hasAlternative;
  final String alternativeName;
  final String alternativeDescription;

  const DeliverableDef({
    required this.id,
    required this.name,
    required this.description,
    this.exampleImage,
    required this.isMandatory,
    this.isToggleable = false,
    this.hasAlternative = false,
    this.alternativeName = 'Alternative',
    this.alternativeDescription = '',
  });
}

/// The mutable, persisted state for a single deliverable id (this id may
/// belong to an original [DeliverableDef] or to a generated alternative
/// tile, whose id is "<originalId>__alt").
class DeliverableState {
  bool isCompleted;
  bool isAvailable;
  bool isExpanded;

  DeliverableState({
    this.isCompleted = false,
    this.isAvailable = true,
    this.isExpanded = false,
  });

  factory DeliverableState.fromJson(Map<String, dynamic> json) {
    return DeliverableState(
      isCompleted: json['isCompleted'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isExpanded: json['isExpanded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'isCompleted': isCompleted,
        'isAvailable': isAvailable,
        'isExpanded': isExpanded,
      };
}

/// A fully-resolved deliverable ready to be rendered: a definition's static
/// fields merged with its current mutable state. Alternative tiles are
/// represented the same way, with [isAlternativeTile] set to true.
class DeliverableItem {
  final String id;
  final String name;
  final String description;
  final String? exampleImage;
  final bool isMandatory;
  final bool isToggleable;
  final bool isAlternativeTile;
  final String? parentId;

  bool isCompleted;
  bool isAvailable;
  bool isExpanded;

  bool get hasMoreInfo => description.trim().isNotEmpty;

  DeliverableItem({
    required this.id,
    required this.name,
    required this.description,
    this.exampleImage,
    required this.isMandatory,
    required this.isToggleable,
    this.isAlternativeTile = false,
    this.parentId,
    required this.isCompleted,
    required this.isAvailable,
    required this.isExpanded,
  });

  factory DeliverableItem.original(DeliverableDef def, DeliverableState s) {
    return DeliverableItem(
      id: def.id,
      name: def.name,
      description: def.description,
      exampleImage: def.exampleImage,
      isMandatory: def.isMandatory,
      isToggleable: def.isToggleable,
      isCompleted: s.isCompleted,
      isAvailable: s.isAvailable,
      isExpanded: s.isExpanded,
    );
  }

  factory DeliverableItem.alternative(DeliverableDef def, DeliverableState s) {
    return DeliverableItem(
      id: alternativeIdFor(def.id),
      name: def.alternativeName,
      description: def.alternativeDescription,
      exampleImage: null,
      isMandatory: def.isMandatory,
      isToggleable: false,
      isAlternativeTile: true,
      parentId: def.id,
      isCompleted: s.isCompleted,
      isAvailable: s.isAvailable,
      isExpanded: s.isExpanded,
    );
  }
}

String alternativeIdFor(String originalId) => '${originalId}__alt';
