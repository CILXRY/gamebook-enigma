import 'dart:math';

class GameEntry {
  final String id;
  String name;

  double? totalPlayHours;
  DateTime? lastPlayed;
  bool isRetired;
  final DateTime addedDate;

  String? characterName;
  int? level;
  String? server;

  Map<String, dynamic> resources;
  String? progress;
  String? notes;

  GameEntry({
    required this.name,
    this.totalPlayHours,
    this.lastPlayed,
    this.isRetired = false,
    DateTime? addedDate,
    this.characterName,
    this.level,
    this.server,
    Map<String, dynamic>? resources,
    this.progress,
    this.notes,
  })  : id = _generateId(),
        addedDate = addedDate ?? DateTime.now(),
        resources = resources ?? {};

  GameEntry._withId({
    required this.id,
    required this.name,
    this.totalPlayHours,
    this.lastPlayed,
    this.isRetired = false,
    required this.addedDate,
    this.characterName,
    this.level,
    this.server,
    Map<String, dynamic>? resources,
    this.progress,
    this.notes,
  }) : resources = resources ?? {};

  static String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99999).toString().padLeft(5, '0');
    return '$timestamp-$random';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalPlayHours': totalPlayHours,
      'lastPlayed': lastPlayed?.toIso8601String(),
      'isRetired': isRetired,
      'addedDate': addedDate.toIso8601String(),
      'characterName': characterName,
      'level': level,
      'server': server,
      'resources': resources,
      'progress': progress,
      'notes': notes,
    };
  }

  factory GameEntry.fromJson(Map<String, dynamic> json) {
    return GameEntry._withId(
      id: json['id'] as String,
      name: json['name'] as String,
      totalPlayHours: (json['totalPlayHours'] as num?)?.toDouble(),
      lastPlayed: json['lastPlayed'] != null
          ? DateTime.tryParse(json['lastPlayed'] as String)
          : null,
      isRetired: json['isRetired'] as bool? ?? false,
      addedDate: DateTime.parse(json['addedDate'] as String),
      characterName: json['characterName'] as String?,
      level: json['level'] as int?,
      server: json['server'] as String?,
      resources: (json['resources'] as Map<String, dynamic>?) ?? {},
      progress: json['progress'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
