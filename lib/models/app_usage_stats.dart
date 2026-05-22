class AppUsageStats {
  final String packageName;
  final int totalTimeForegroundMs;
  final int lastTimeUsed;
  final int lastTimeVisible;

  AppUsageStats({
    required this.packageName,
    required this.totalTimeForegroundMs,
    required this.lastTimeUsed,
    required this.lastTimeVisible,
  });

  int get totalTimeSeconds => (totalTimeForegroundMs / 1000).round();

  DateTime? get lastUsedDate =>
      lastTimeUsed > 0 ? DateTime.fromMillisecondsSinceEpoch(lastTimeUsed) : null;

  factory AppUsageStats.fromMap(Map<String, dynamic> map) {
    return AppUsageStats(
      packageName: (map['packageName'] as String?) ?? '',
      totalTimeForegroundMs: (map['totalTimeForegroundMs'] as num?)?.toInt() ?? 0,
      lastTimeUsed: (map['lastTimeUsed'] as num?)?.toInt() ?? 0,
      lastTimeVisible: (map['lastTimeVisible'] as num?)?.toInt() ?? 0,
    );
  }
}
