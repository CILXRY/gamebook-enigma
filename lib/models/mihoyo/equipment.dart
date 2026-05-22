class Equipment {
  final int id;
  final int level;
  final int rank;
  final String name;
  final String desc;
  final String icon;
  final int rarity;
  final Map<String, dynamic> extra;

  Equipment({
    required this.id,
    required this.level,
    required this.rank,
    required this.name,
    required this.desc,
    required this.icon,
    required this.rarity,
    Map<String, dynamic>? extra,
  }) : extra = extra ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level,
      'rank': rank,
      'name': name,
      'desc': desc,
      'icon': icon,
      'rarity': rarity,
      ...extra,
    };
  }

  factory Equipment.fromJson(Map<String, dynamic> json) {
    const knownKeys = {
      'id', 'level', 'rank', 'name', 'desc', 'icon', 'rarity',
    };
    final extra = Map<String, dynamic>.from(json)
      ..removeWhere((k, _) => knownKeys.contains(k));

    return Equipment(
      id: json['id'] as int,
      level: json['level'] as int,
      rank: json['rank'] as int,
      name: json['name'] as String,
      desc: json['desc'] as String? ?? '',
      icon: json['icon'] as String,
      rarity: json['rarity'] as int,
      extra: extra,
    );
  }
}
