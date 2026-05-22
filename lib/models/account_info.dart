class AccountInfo {
  String? characterName;
  int? level;
  String? server;
  Map<String, dynamic> resources;
  int? spending;

  AccountInfo({
    this.characterName,
    this.level,
    this.server,
    Map<String, dynamic>? resources,
    this.spending,
  }) : resources = resources ?? {};

  Map<String, dynamic> toJson() {
    return {
      'characterName': characterName,
      'level': level,
      'server': server,
      'resources': resources,
      'spending': spending,
    };
  }

  factory AccountInfo.fromJson(Map<String, dynamic> json) {
    return AccountInfo(
      characterName: json['characterName'] as String?,
      level: json['level'] as int?,
      server: json['server'] as String?,
      resources: (json['resources'] as Map<String, dynamic>?) ?? {},
      spending: json['spending'] as int?,
    );
  }
}
