import 'collection_stats.dart';
import 'character.dart';

class HoyoGameProfile {
  final String gameBiz;
  String gameName;
  String gameUid;
  String gameNickname;
  int gameLevel;
  String gameServer;
  CollectionStats collections;
  List<Character> avatarList;
  final DateTime fetchedAt;
  final Map<String, dynamic> extra;

  HoyoGameProfile({
    required this.gameBiz,
    required this.gameName,
    required this.gameUid,
    required this.gameNickname,
    required this.gameLevel,
    required this.gameServer,
    required this.collections,
    List<Character>? avatarList,
    DateTime? fetchedAt,
    Map<String, dynamic>? extra,
  })  : avatarList = avatarList ?? [],
        fetchedAt = fetchedAt ?? DateTime.now(),
        extra = extra ?? {};

  Map<String, dynamic> toJson() {
    return {
      'game_biz': gameBiz,
      'game_name': gameName,
      'game_uid': gameUid,
      'game_nickname': gameNickname,
      'game_level': gameLevel,
      'game_server': gameServer,
      'collections': collections.toJson(),
      'avatars_list': avatarList.map((c) => c.toJson()).toList(),
      'fetched_at': fetchedAt.toIso8601String(),
      ...extra,
    };
  }

  factory HoyoGameProfile.fromJson(Map<String, dynamic> json) {
    const knownKeys = {
      'game_biz', 'game_name', 'game_uid', 'game_nickname',
      'game_level', 'game_server', 'collections', 'avatars_list',
      'fetched_at',
    };
    final extra = Map<String, dynamic>.from(json)
      ..removeWhere((k, _) => knownKeys.contains(k));

    return HoyoGameProfile(
      gameBiz: json['game_biz'] as String,
      gameName: json['game_name'] as String,
      gameUid: json['game_uid'] as String,
      gameNickname: json['game_nickname'] as String,
      gameLevel: json['game_level'] as int,
      gameServer: json['game_server'] as String,
      collections: CollectionStats.fromJson(
          json['collections'] as Map<String, dynamic>),
      avatarList: (json['avatars_list'] as List<dynamic>?)
              ?.map((e) => Character.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      fetchedAt: json['fetched_at'] != null
          ? DateTime.tryParse(json['fetched_at'] as String)
          : null,
      extra: extra,
    );
  }
}
