class UserGameRole {
  final String gameBiz;
  final String region;
  final String gameUid;
  final String nickname;
  final int? level;
  final String regionName;
  final bool isOfficial;
  final Map<String, dynamic> extra;

  const UserGameRole({
    required this.gameBiz,
    required this.region,
    required this.gameUid,
    required this.nickname,
    this.level,
    required this.regionName,
    this.isOfficial = true,
    this.extra = const {},
  });

  factory UserGameRole.fromJson(Map<String, dynamic> json) {
    return UserGameRole(
      gameBiz: json['game_biz'] as String? ?? '',
      region: json['region'] as String? ?? '',
      gameUid: json['game_uid'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      level: json['level'] as int?,
      regionName: json['region_name'] as String? ?? '',
      isOfficial: json['is_official'] as bool? ?? true,
      extra: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => {
        'game_biz': gameBiz,
        'region': region,
        'game_uid': gameUid,
        'nickname': nickname,
        'level': level,
        'region_name': regionName,
        'is_official': isOfficial,
        ...extra,
      };

  String get gameName {
    switch (gameBiz) {
      case 'hkrpg_cn':
        return '崩坏：星穹铁道';
      case 'hk4e_cn':
        return '原神';
      case 'nap_cn':
        return '绝区零';
      default:
        return gameBiz;
    }
  }
}
