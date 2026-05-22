import 'equipment.dart';

class Character {
  final int id;
  final int level;
  final String name;
  final String element;
  final String icon;
  final int rarity;
  final int rank;
  final bool isChosen;
  final Equipment? equip;
  final int baseType;
  final String figurePath;
  final int elementId;
  final Map<String, dynamic> extra;

  Character({
    required this.id,
    required this.level,
    required this.name,
    required this.element,
    required this.icon,
    required this.rarity,
    required this.rank,
    required this.isChosen,
    this.equip,
    required this.baseType,
    required this.figurePath,
    required this.elementId,
    Map<String, dynamic>? extra,
  }) : extra = extra ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level,
      'name': name,
      'element': element,
      'icon': icon,
      'rarity': rarity,
      'rank': rank,
      'is_chosen': isChosen,
      'equip': equip?.toJson(),
      'base_type': baseType,
      'figure_path': figurePath,
      'element_id': elementId,
      ...extra,
    };
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    const knownKeys = {
      'id', 'level', 'name', 'element', 'icon', 'rarity', 'rank',
      'is_chosen', 'equip', 'base_type', 'figure_path', 'element_id',
    };
    final extra = Map<String, dynamic>.from(json)
      ..removeWhere((k, _) => knownKeys.contains(k));

    return Character(
      id: json['id'] as int,
      level: json['level'] as int,
      name: json['name'] as String,
      element: json['element'] as String,
      icon: json['icon'] as String,
      rarity: json['rarity'] as int,
      rank: json['rank'] as int,
      isChosen: json['is_chosen'] as bool? ?? false,
      equip: json['equip'] != null
          ? Equipment.fromJson(json['equip'] as Map<String, dynamic>)
          : null,
      baseType: json['base_type'] as int,
      figurePath: json['figure_path'] as String,
      elementId: json['element_id'] as int,
      extra: extra,
    );
  }
}
