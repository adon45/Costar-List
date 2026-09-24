class RoomBucket {
  final String id;
  final String name;
  int photoCount;
  bool isCompleted;
  bool isExpanded;

  RoomBucket({
    required this.id,
    required this.name,
    this.photoCount = 0,
    this.isCompleted = false,
    this.isExpanded = false,
  });

  factory RoomBucket.fromJson(Map<String, dynamic> json) {
    return RoomBucket(
      id: json['id'] as String,
      name: json['name'] as String,
      photoCount: json['photoCount'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isExpanded: json['isExpanded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'photoCount': photoCount,
        'isCompleted': isCompleted,
        'isExpanded': isExpanded,
      };
}
