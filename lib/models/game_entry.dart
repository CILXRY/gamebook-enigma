import 'game_atom_model.dart';
import 'account_info.dart';
import 'tag_fill.dart';
import 'mihoyo/hoyo_game_profile.dart';

class GameEntry extends GameAtomModel {
  bool isRetired;

  AccountInfo? accountInfo;

  String? progress;

  List<TagFill> tagFills;
  int? recommendation;
  int? returnBarrier;

  HoyoGameProfile? hoyoProfile;

  String? linkedPackageName;

  GameEntry({
    super.gameId,
    super.gameAddedInTime,
    required super.gameName,
    super.gameLastLaunched,
    super.gamePlayedSeconds,
    super.notes,

    this.isRetired = false,
    this.accountInfo,
    this.progress,
    List<TagFill>? tagFills,
    this.recommendation,
    this.returnBarrier,
    this.hoyoProfile,
    this.linkedPackageName,
  }) : tagFills = tagFills ?? [];

  // ignore: unused_element
  GameEntry._withId({
    required String id,
    required DateTime addedDate,
    required String name,
    double? totalPlayHours,
    DateTime? lastPlayed,
    this.isRetired = false,
    super.notes,

    this.accountInfo,
    this.progress,
    List<TagFill>? tagFills,
    this.recommendation,
    this.returnBarrier,
    this.hoyoProfile,
    this.linkedPackageName,
  }) : tagFills = tagFills ?? [],
       super(
         gameId: id,
         gameAddedInTime: addedDate,
         gameName: name,
         gamePlayedSeconds: totalPlayHours != null ? (totalPlayHours * 3600).round() : 0,
         gameLastLaunched: lastPlayed,
       );

  @override
  Map<String, dynamic> toJson() {
    final json = super.toBaseJson();

    json.addAll({
      'isRetired': isRetired,
      'accountInfo': accountInfo?.toJson(),
      'progress': progress,
      'tagFills': tagFills.map((tf) => tf.toJson()).toList(),
      'recommendation': recommendation,
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

    AccountInfo? accountInfo;
    if (json['accountInfo'] is Map<String, dynamic>) {
      accountInfo = AccountInfo.fromJson(json['accountInfo'] as Map<String, dynamic>);
    } else if (json['characterName'] != null ||
        json['level'] != null ||
        json['server'] != null ||
        json['spending'] != null) {
      accountInfo = AccountInfo(
        characterName: json['characterName'] as String?,
        level: json['level'] as int?,
        server: json['server'] as String?,
        resources: (json['resources'] as Map<String, dynamic>?) ?? {},
        spending: json['spending'] as int?,
      );
    }

    List<TagFill> tagFills;
    if (json['tagFills'] != null && json['tagFills'] is List) {
      tagFills = (json['tagFills'] as List)
          .map((e) => TagFill.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else if (json['tags'] != null && json['tags'] is List) {
      tagFills = (json['tags'] as List)
          .map((e) => TagFill(sentenceKey: 'tag', tag: e.toString()))
          .toList();
    } else {
      tagFills = [];
    }

    return GameEntry(
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

      isRetired: json['isRetired'] as bool? ?? false,
      accountInfo: accountInfo,
      progress: json['progress'] as String?,
      tagFills: tagFills,
      recommendation: json['recommendation'] as int?,
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
