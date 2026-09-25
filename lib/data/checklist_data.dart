import '../models/deliverable.dart';
import '../models/media_type.dart';
import '../models/room_bucket.dart';

class PhotoRange {
  final int minimum;
  final int maximum;

  const PhotoRange(this.minimum, this.maximum);

  int get midpoint => (minimum + maximum) ~/ 2;
}

const homesPlatinumBucketNames = [
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
];

List<RoomBucket> createHomesPlatinumBuckets() => homesPlatinumBucketNames
    .map((name) => RoomBucket(id: _slug(name), name: name))
    .toList();

PhotoRange homesPlatinumPhotoRange(String? subtype) {
  switch (subtype) {
    case '0–2,000 sqft':
      return const PhotoRange(35, 40);
    case '2,000–4,000 sqft':
      return const PhotoRange(45, 50);
    case '4,000–6,000 sqft':
      return const PhotoRange(60, 65);
    case '6,000–8,000 sqft':
      return const PhotoRange(70, 75);
    case '8,000+ sqft':
      return const PhotoRange(75, 80);
    default:
      return const PhotoRange(35, 40);
  }
}

List<DeliverableDef> getChecklist(MediaType type, String? subtype) {
  switch (type) {
    case MediaType.photoAssignments:
      return _photoAssignments(subtype);
    case MediaType.homesPlatinum:
      return _homesPlatinum(subtype);
    case MediaType.statusVerifications:
      return _statusVerifications(subtype);
    case MediaType.apartmentsGold:
    case MediaType.apartmentsPlatinum:
    case MediaType.apartmentsDiamond:
    case MediaType.homesMatterport:
      return const [];
  }
}

List<DeliverableDef> _photoAssignments(String? subtype) {
  switch (subtype) {
    case 'Industrial':
      return [
        _required('primary_image', 'Primary Image'),
        _required('alternates', 'Alternate(s)'),
        _required('signage', 'Signage', 'Property or monument signage.'),
        _required(
            'loading_perspective',
            'One-point perspective of loading side',
            'Use a one-point perspective looking along the loading side.'),
        _required('entrance', 'Entrance'),
        _optional('lobby', 'Lobby (when present)'),
        _required('aerial', 'Aerial Context',
            'Show the property in its surrounding context.'),
        _required('lookdown', '90° Look Down',
            'Capture a straight-down 90 degree view of the property.'),
      ];
    case 'Office':
      return [
        _required('primary_image', 'Primary Image'),
        _required('alternates', 'Alternate Building Images'),
        _required('signage', 'Signage'),
        _required('loading', 'Loading Ramps / Docks / Drive-in Bays',
            'Show loading ramps, loading docks, and drive-in bays.'),
        _required('garages', 'Garages'),
        _required('entrance', 'Entrance'),
        _optional('lobby', 'Lobby (when possible)'),
        _required('aerial', 'Aerial Context',
            'Show the property in its surrounding context.'),
        _required('lookdown', '90° Look Down',
            'Capture a straight-down 90 degree view of the property.'),
      ];
    case 'Retail':
      return [
        _required('primary_image', 'Primary Image'),
        _required('alternates', 'Alternate Building Images'),
        _required('signage', 'Signage', 'Show storefront or monument signage.'),
        _required('loading', 'Loading Ramps / Docks / Drive-in Bays',
            'Show loading ramps, loading docks, and drive-in bays.'),
        _required('garages', 'Garages'),
        _optional('anchor_store', 'Anchor Store (if not in primary)'),
        _required('aerial', 'Aerial Context',
            'Show the property in its surrounding context.'),
        _required('lookdown', '90° Look Down',
            'Capture a straight-down 90 degree view of the property.'),
      ];
    case 'Multifamily':
      return [
        _required('primary_image', 'Primary Image'),
        _required('alternates', 'Alternate Community Images'),
        _optional('clubhouse', 'Clubhouse (if available)'),
        _optional('amenities', 'Amenities Overview (if available)'),
        _required('main_tower_entrance', 'Entrance of main tower'),
        _optional('lobby', 'Lobby (when accessible)'),
        _required('aerial', 'Aerial Context',
            'Show the property in its surrounding context.'),
        _required('lookdown', '90° Look Down',
            'Capture a straight-down 90 degree view of the property.'),
      ];
    default:
      return const [];
  }
}

DeliverableDef _required(String id, String name, [String description = '']) =>
    DeliverableDef(
      id: id,
      name: name,
      description: description,
      isMandatory: false,
      isToggleable: true,
    );

DeliverableDef _optional(String id, String name, [String description = '']) =>
    DeliverableDef(
      id: id,
      name: name,
      description: description,
      isMandatory: false,
      isToggleable: true,
    );

List<DeliverableDef> _homesPlatinum(String? subtype) {
  return const [];
}

String _slug(String name) => name
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

List<DeliverableDef> _statusVerifications(String? subtype) {
  switch (subtype) {
    case 'Proposed':
    case 'Final Planning':
    case 'Under Construction':
      return [
        _status('construction_signage', 'Construction Signage',
            'Show the construction or development signage.'),
        _status('primary_construction', 'Primary Construction Photo'),
        _status('alternate_construction', 'Alternate Construction Photo',
            'Usually capture an Aerial Context view.'),
      ];
    case 'Existing':
      return [
        _status('primary_image', 'Primary Image'),
        _status('alternates', '1–3 Alternates'),
        _status('entrance', 'Entrance'),
        _status('lobby', 'Lobby (when possible)'),
        _status('aerial_context', 'Aerial / Context',
            'Show the property and its surrounding context.'),
      ];
    default:
      return const [];
  }
}

DeliverableDef _status(String id, String name, [String description = '']) =>
    DeliverableDef(
      id: id,
      name: name,
      description: description,
      isMandatory: true,
      isToggleable: true,
      hasAlternative: true,
    );
