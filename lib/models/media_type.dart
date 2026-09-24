/// The top-level assignment categories shown on the Media Types screen.
enum MediaType {
  photoAssignments,
  apartmentsGold,
  apartmentsPlatinum,
  apartmentsDiamond,
  homesPlatinum,
  homesMatterport,
  statusVerifications,
}

/// Static configuration describing how a [MediaType] should be presented
/// on the Media Types screen and whether it has a defined checklist yet.
class MediaTypeConfig {
  final MediaType type;
  final String title;
  final bool comingSoon;
  final List<String> subtypes;

  const MediaTypeConfig({
    required this.type,
    required this.title,
    this.comingSoon = false,
    this.subtypes = const [],
  });

  bool get hasSubtypes => subtypes.isNotEmpty;
}

/// The full list of assignment types, in the order they should render.
const List<MediaTypeConfig> mediaTypeConfigs = [
  MediaTypeConfig(
    type: MediaType.photoAssignments,
    title: 'Photo Assignments',
    subtypes: ['Industrial', 'Office', 'Retail', 'Multifamily'],
  ),
  MediaTypeConfig(
    type: MediaType.apartmentsGold,
    title: 'Apartments Gold Media Shoot',
    comingSoon: true,
  ),
  MediaTypeConfig(
    type: MediaType.apartmentsPlatinum,
    title: 'Apartments Platinum Media Shoot',
    comingSoon: true,
  ),
  MediaTypeConfig(
    type: MediaType.apartmentsDiamond,
    title: 'Apartments Diamond Media Shoot',
    comingSoon: true,
  ),
  MediaTypeConfig(
    type: MediaType.homesPlatinum,
    title: 'Homes Platinum Shoot',
    subtypes: [
      '0–2,000 sqft',
      '2,000–4,000 sqft',
      '4,000–6,000 sqft',
      '6,000–8,000 sqft',
      '8,000+ sqft',
    ],
  ),
  MediaTypeConfig(
    type: MediaType.homesMatterport,
    title: 'Homes Matterport Shoot',
    comingSoon: true,
  ),
  MediaTypeConfig(
    type: MediaType.statusVerifications,
    title: 'Status Verifications',
    subtypes: ['Proposed', 'Final Planning', 'Under Construction', 'Existing'],
  ),
];

MediaTypeConfig configFor(MediaType type) =>
    mediaTypeConfigs.firstWhere((c) => c.type == type);

/// Builds the unique storage/lookup key for an assignment: a media type
/// combined with its optional sub-type (e.g. "photoAssignments::Industrial").
String assignmentKey(MediaType type, String? subtype) {
  final base = type.name;
  if (subtype == null || subtype.isEmpty) return base;
  return '$base::$subtype';
}
