import '../models/deliverable.dart';
import '../models/media_type.dart';

/// Returns the ordered list of deliverable definitions for a given
/// [MediaType] and optional [subtype]. Returns an empty list for any
/// "Coming Soon" media type, since it has no defined checklist yet.
List<DeliverableDef> getChecklist(MediaType type, String? subtype) {
  switch (type) {
    case MediaType.photoAssignments:
      return _photoAssignments(subtype);
    case MediaType.homesPlatinum:
      return _homesPlatinum();
    case MediaType.statusVerifications:
      return _statusVerifications(subtype);
    case MediaType.apartmentsGold:
    case MediaType.apartmentsPlatinum:
    case MediaType.apartmentsDiamond:
    case MediaType.homesMatterport:
      return const [];
  }
}

// ---------------------------------------------------------------------------
// Photo Assignments
// ---------------------------------------------------------------------------

List<DeliverableDef> _photoAssignments(String? subtype) {
  switch (subtype) {
    case 'Industrial':
      return _photoCommonMandatory() + _industrialOptional();
    case 'Office':
      return _photoCommonMandatory() + _officeOptional();
    case 'Retail':
      return _retailMandatory() + _retailOptional();
    case 'Multifamily':
      return _multifamilyMandatory() + _multifamilyOptional();
    default:
      return const [];
  }
}

List<DeliverableDef> _photoCommonMandatory() => const [
      DeliverableDef(
        id: 'primary',
        name: 'Primary',
        description: 'The main hero shot representing the property.',
        isMandatory: true,
      ),
      DeliverableDef(
        id: 'alternate',
        name: 'Alternate',
        description: 'A secondary angle of the primary subject.',
        isMandatory: true,
      ),
      DeliverableDef(
        id: 'aerial_context',
        name: 'Aerial Context',
        description: 'Drone shot showing the property in its surroundings.',
        isMandatory: true,
      ),
      DeliverableDef(
        id: 'lookdown_90',
        name: '90° Lookdown',
        description: 'Straight-down drone shot directly over the property.',
        isMandatory: true,
      ),
      DeliverableDef(
        id: 'entrance_photo',
        name: 'Entrance Photo',
        description: 'Clear shot of the main entrance / front door area.',
        isMandatory: true,
      ),
    ];

List<DeliverableDef> _photoCommonOptional() => const [
      DeliverableDef(
        id: 'alternate_2',
        name: 'Alternate 2',
        description: 'Additional alternate angle of the property.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'alternate_3',
        name: 'Alternate 3',
        description: 'A further alternate angle, if available.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'loading_ramps',
        name: 'Loading Ramps',
        description: 'Shot of loading ramp access points.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'loading_docks',
        name: 'Loading Docks',
        description: 'Shot of loading dock doors and staging area.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'drive_in_bays',
        name: 'Drive-in Bays',
        description: 'Shot of grade-level drive-in bay doors.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'garages',
        name: 'Garages',
        description: 'Shot of attached or detached garage structures.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
    ];

List<DeliverableDef> _industrialOptional() => [
      ..._photoCommonOptional(),
      const DeliverableDef(
        id: 'lobby',
        name: 'Lobby',
        description: 'Interior shot of the building lobby.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
    ];

List<DeliverableDef> _officeOptional() => _industrialOptional();

List<DeliverableDef> _retailMandatory() => const [
      DeliverableDef(
        id: 'primary',
        name: 'Primary',
        description: 'The main hero shot representing the property.',
        isMandatory: true,
      ),
      DeliverableDef(
        id: 'alternate',
        name: 'Alternate',
        description: 'A secondary angle of the primary subject.',
        isMandatory: true,
      ),
      DeliverableDef(
        id: 'aerial_context',
        name: 'Aerial Context',
        description: 'Drone shot showing the property in its surroundings.',
        isMandatory: true,
      ),
      DeliverableDef(
        id: 'lookdown_90',
        name: '90° Lookdown',
        description: 'Straight-down drone shot directly over the property.',
        isMandatory: true,
      ),
      DeliverableDef(
        id: 'signage',
        name: 'Signage',
        description: 'Clear shot of storefront / monument signage.',
        isMandatory: true,
      ),
    ];

List<DeliverableDef> _retailOptional() => const [
      DeliverableDef(
        id: 'alternate_2',
        name: 'Alternate 2',
        description: 'Additional alternate angle of the property.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'alternate_3',
        name: 'Alternate 3',
        description: 'A further alternate angle, if available.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'loading_ramps',
        name: 'Loading Ramps',
        description: 'Shot of loading ramp access points.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'loading_docks',
        name: 'Loading Docks',
        description: 'Shot of loading dock doors and staging area.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'drive_in_bays',
        name: 'Drive-in Bays',
        description: 'Shot of grade-level drive-in bay doors.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'garages',
        name: 'Garages',
        description: 'Shot of attached or detached garage structures.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
    ];

List<DeliverableDef> _multifamilyMandatory() => const [
      DeliverableDef(
        id: 'primary',
        name: 'Primary',
        description: 'The main hero shot representing the property.',
        isMandatory: true,
      ),
      DeliverableDef(
        id: 'alternate',
        name: 'Alternate',
        description: 'A secondary angle of the primary subject.',
        isMandatory: true,
      ),
      DeliverableDef(
        id: 'aerial_context',
        name: 'Aerial Context',
        description: 'Drone shot showing the property in its surroundings.',
        isMandatory: true,
      ),
      DeliverableDef(
        id: 'lookdown_90',
        name: '90° Lookdown',
        description: 'Straight-down drone shot directly over the property.',
        isMandatory: true,
      ),
      DeliverableDef(
        id: 'community_building_alternate',
        name: 'Community/Building Alternate',
        description: 'Alternate angle of a community building.',
        isMandatory: true,
      ),
      DeliverableDef(
        id: 'main_tower_entrance',
        name: 'Main Tower/Entrance',
        description: 'Shot of the main tower or community entrance.',
        isMandatory: true,
      ),
    ];

List<DeliverableDef> _multifamilyOptional() => const [
      DeliverableDef(
        id: 'alternate_2',
        name: 'Alternate 2',
        description: 'Additional alternate angle of the property.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'alternate_3',
        name: 'Alternate 3',
        description: 'A further alternate angle, if available.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'lobby',
        name: 'Lobby',
        description: 'Interior shot of the building lobby.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'amenities_overview',
        name: 'Amenities Overview',
        description: 'Wide shot showing the amenity spaces.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'clubhouse',
        name: 'Clubhouse',
        description: 'Shot of the community clubhouse.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
    ];

// ---------------------------------------------------------------------------
// Homes Platinum Shoot -- 20 toggleable mandatory deliverables
// ---------------------------------------------------------------------------

List<DeliverableDef> _homesPlatinum() {
  const names = [
    'Front Exterior',
    'Rear Exterior',
    'Patio/Deck',
    'Entry',
    'Living Room',
    'Living Room (2)',
    'Dining Room',
    'Kitchen',
    'Kitchen (2)',
    'Primary BR',
    'Primary BR (2)',
    'Primary BA',
    'Bedroom 2',
    'Bedroom 3',
    'Bathroom 2',
    'Bathroom 3',
    'Family Room',
    'Laundry Room',
    'Garage Interior',
    'Twilight Exterior',
  ];

  return names
      .map(
        (name) => DeliverableDef(
          id: _slug(name),
          name: name,
          description: 'Capture $name per the Homes Platinum shot list.',
          isMandatory: true,
          isToggleable: true,
          hasAlternative: true,
        ),
      )
      .toList();
}

String _slug(String name) => name
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

// ---------------------------------------------------------------------------
// Status Verifications
// ---------------------------------------------------------------------------

List<DeliverableDef> _statusVerifications(String? subtype) {
  switch (subtype) {
    case 'Proposed':
    case 'Final Planning':
    case 'Under Construction':
      return _statusSimple();
    case 'Existing':
      return _statusExisting();
    default:
      return const [];
  }
}

List<DeliverableDef> _statusSimple() => const [
      DeliverableDef(
        id: 'construction_signage',
        name: 'Construction Signage',
        description: 'Shot of on-site construction/development signage.',
        isMandatory: true,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'primary',
        name: 'Primary',
        description: 'The main hero shot representing the site status.',
        isMandatory: true,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'alternative_shot',
        name: 'Alternative',
        description: 'Secondary status shot from a different angle.',
        isMandatory: true,
        isToggleable: true,
        hasAlternative: true,
      ),
    ];

List<DeliverableDef> _statusExisting() => const [
      DeliverableDef(
        id: 'primary',
        name: 'Primary',
        description: 'The main hero shot representing the property.',
        isMandatory: true,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'alternate',
        name: 'Alternate',
        description: 'A secondary angle of the primary subject.',
        isMandatory: true,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'entrance',
        name: 'Entrance',
        description: 'Clear shot of the main entrance.',
        isMandatory: true,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'aerial',
        name: 'Aerial',
        description: 'Drone shot showing the property from above.',
        isMandatory: true,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'alternate_2',
        name: 'Alternate 2',
        description: 'Additional alternate angle of the property.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
      DeliverableDef(
        id: 'alternate_3',
        name: 'Alternate 3',
        description: 'A further alternate angle, if available.',
        isMandatory: false,
        isToggleable: true,
        hasAlternative: true,
      ),
    ];
