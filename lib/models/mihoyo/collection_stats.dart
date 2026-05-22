class CollectionStats {
  int activeDays;
  int avatarsCollected;
  int achievementsCollected;
  int chestCollected;
  final Map<String, dynamic> extra;

  CollectionStats({
    required this.activeDays,
    required this.avatarsCollected,
    required this.achievementsCollected,
    required this.chestCollected,
    Map<String, dynamic>? extra,
  }) : extra = extra ?? {};

  Map<String, dynamic> toJson() {
    return {
      'active_days': activeDays,
      'avatars_collected': avatarsCollected,
      'achievements_collected': achievementsCollected,
      'chest_collected': chestCollected,
      ...extra,
    };
  }

  factory CollectionStats.fromJson(Map<String, dynamic> json) {
    const knownKeys = {
      'active_days', 'avatars_collected', 'achievements_collected',
      'chest_collected',
    };
    final extra = Map<String, dynamic>.from(json)
      ..removeWhere((k, _) => knownKeys.contains(k));

    return CollectionStats(
      activeDays: json['active_days'] as int,
      avatarsCollected: json['avatars_collected'] as int,
      achievementsCollected: json['achievements_collected'] as int,
      chestCollected: json['chest_collected'] as int,
      extra: extra,
    );
  }
}
