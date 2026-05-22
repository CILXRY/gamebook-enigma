// 最原子的游戏类型定义
import 'dart:math';

class GameAtomModel {
  // Added-in
  final String id;
  final DateTime gameAddedInTime;

  // Gameplay Related Infos
  String gameName;
  DateTime? gameLastLaunched;
  int gamePlayedSeconds;

  String? notes;

  GameAtomModel({
    // 允许传入用于反序列化
    String? gameId,
    DateTime? gameAddedInTime,

    required this.gameName,
    this.gameLastLaunched,
    this.gamePlayedSeconds = 0,
    this.notes,
  }) : id = gameId ?? _generateId(),
       gameAddedInTime = gameAddedInTime ?? DateTime.now();

  static String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(99999).toString().padLeft(5, '0');
    return '$timestamp-$random';
  }

  static int playHoursToSeconds(String text) {
    final hours = double.tryParse(text);
    if (hours == null) return 0;
    return (hours * 3600).round();
  }

  // 把 toJson 抽出来，这样子类就不用关注 atom 字段的toJson了
  Map<String, dynamic> toBaseJson() {
    return {
      'id': id,
      'gameName': gameName,
      'gamePlayedSeconds': gamePlayedSeconds,
      'gameLastLaunched': gameLastLaunched?.toIso8601String(),
      'gameAddedInTime': gameAddedInTime.toIso8601String(),
      'notes': notes,
    };
  }
}
