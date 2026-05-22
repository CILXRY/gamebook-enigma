import 'game_atom_model.dart';
import 'mihoyo/hoyo_game_profile.dart';

class GameEntry extends GameAtomModel {
  // --- GameEntry Specific Fields ---
  bool isRetired;

  String? characterName;
  int? level;
  String? server;

  Map<String, dynamic> resources;
  String? progress;

  List<String> tags;
  int? recommendation;
  int? spending;
  int? returnBarrier;

  HoyoGameProfile? hoyoProfile;

  String? linkedPackageName;

  GameEntry({
    // 基类字段通过 super 传递
    super.gameId,
    super.gameAddedInTime,
    required super.gameName, // 对应原来的 name
    super.gameLastLaunched, // 对应原来的 lastPlayed
    super.gamePlayedSeconds, // 对应原来的 totalPlayHours
    super.notes,

    // 子类字段
    this.isRetired = false,
    this.characterName,
    this.level,
    this.server,
    Map<String, dynamic>? resources,
    this.progress,
    List<String>? tags,
    this.recommendation,
    this.spending,
    this.returnBarrier,
    this.hoyoProfile,
    this.linkedPackageName,
  }) : resources = resources ?? {},
       tags = tags ?? [];

  /// 内部构造函数，主要用于测试或特殊初始化，通常 fromJson 更常用
  // ignore: unused_element
  GameEntry._withId({
    required String id,
    required DateTime addedDate,
    required String name,
    double? totalPlayHours,
    DateTime? lastPlayed,
    this.isRetired = false,
    super.notes,

    this.characterName,
    this.level,
    this.server,
    Map<String, dynamic>? resources,
    this.progress,
    List<String>? tags,
    this.recommendation,
    this.spending,
    this.returnBarrier,
    this.hoyoProfile,
    this.linkedPackageName,
  }) : resources = resources ?? {},
       tags = tags ?? [],
       super(
         gameId: id,
         gameAddedInTime: addedDate,
         gameName: name,
         gamePlayedSeconds: totalPlayHours != null ? (totalPlayHours * 3600).round() : 0,
         gameLastLaunched: lastPlayed,
       );

  @override
  Map<String, dynamic> toJson() {
    // 获取基类 JSON
    final json = super.toBaseJson();

    // 合并子类特有字段
    // 注意：基类 toBaseJson 返回的是 'gameName', 'gamePlayedHours' 等 key
    // 如果你的 API 需要扁平化的 'name', 'totalPlayHours'，你需要在这里做 key 的重命名或映射
    // 下面假设保持基类的 key 命名风格，或者你可以根据需求调整 key 名称

    json.addAll({
      'isRetired': isRetired,
      'characterName': characterName,
      'level': level,
      'server': server,
      'resources': resources,
      'progress': progress,
      'tags': tags,
      'recommendation': recommendation,
      'spending': spending,
      'returnBarrier': returnBarrier,
      'hoyoProfile': hoyoProfile?.toJson(),
      'linkedPackageName': linkedPackageName,
    });

    return json;
  }

  factory GameEntry.fromJson(Map<String, dynamic> json) {
    final rawPlayed = json['gamePlayedSeconds'] ?? json['gamePlayedHours'];
    var gamePlayedSeconds = 0;
    if (rawPlayed is int) {
      gamePlayedSeconds = rawPlayed;
    } else if (rawPlayed is double) {
      gamePlayedSeconds = (rawPlayed * 3600).round();
    } else if (rawPlayed is num) {
      gamePlayedSeconds = rawPlayed.toInt();
    }

    return GameEntry(
      // 基类字段
      gameId: json['id'] as String?,
      gameAddedInTime: json['gameAddedInTime'] != null
          ? DateTime.parse(json['gameAddedInTime'] as String)
          : null,
      gameName: json['gameName'] as String,
      gamePlayedSeconds: gamePlayedSeconds,
      gameLastLaunched: json['gameLastLaunched'] != null
          ? DateTime.tryParse(json['gameLastLaunched'] as String)
          : null,
      notes: json['notes'] as String?,

      // 子类字段
      isRetired: json['isRetired'] as bool? ?? false,
      characterName: json['characterName'] as String?,
      level: json['level'] as int?,
      server: json['server'] as String?,
      resources: (json['resources'] as Map<String, dynamic>?) ?? {},
      progress: json['progress'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      recommendation: json['recommendation'] as int?,
      spending: json['spending'] as int?,
      returnBarrier: json['returnBarrier'] as int?,
      hoyoProfile: json['hoyoProfile'] != null
          ? HoyoGameProfile.fromJson(
              json['hoyoProfile'] as Map<String, dynamic>,
            )
          : null,
      linkedPackageName: json['linkedPackageName'] as String?,
    );
  }
}
