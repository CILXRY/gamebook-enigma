import '../models/app_usage_stats.dart';
import '../models/game_entry.dart';
import 'usage_stats_service.dart';
import 'package_info_service.dart';

class LocalGameSyncService {
  static Future<List<GameEntry>> syncAllLinked(List<GameEntry> games) async {
    final allStats = await UsageStatsService.getAllUsageStats();
    final statsByPackage = <String, AppUsageStats>{};
    for (final s in allStats) {
      statsByPackage[s.packageName] = s;
    }

    final permissionGranted = await PackageInfoService.isUsagePermissionGranted();

    for (final game in games) {
      if (game.linkedPackageName == null) continue;
      final stats = statsByPackage[game.linkedPackageName];
      if (stats == null) continue;

      if (stats.totalTimeForegroundMs > 0) {
        game.gamePlayedSeconds = stats.totalTimeSeconds;
      }
      if (stats.lastTimeUsed > 0) {
        game.gameLastLaunched = DateTime.fromMillisecondsSinceEpoch(stats.lastTimeUsed);
      }

      if (permissionGranted && stats.totalTimeForegroundMs == 0) {
        game.isRetired = true;
      }
    }

    return games;
  }

  static Future<GameEntry> syncSingle(GameEntry game) async {
    if (game.linkedPackageName == null) return game;

    final statsList = await UsageStatsService.getUsageStatsForPackage(
      game.linkedPackageName!,
    );

    double totalMs = 0;
    int latestUsed = 0;
    for (final s in statsList) {
      totalMs += s.totalTimeForegroundMs;
      if (s.lastTimeUsed > latestUsed) latestUsed = s.lastTimeUsed;
    }

    if (totalMs > 0) {
      game.gamePlayedSeconds = (totalMs / 1000).round();
    }
    if (latestUsed > 0) {
      game.gameLastLaunched = DateTime.fromMillisecondsSinceEpoch(latestUsed);
    }

    if (game.linkedPackageName != null &&
        await PackageInfoService.isUsagePermissionGranted() &&
        totalMs == 0) {
      game.isRetired = true;
    }

    return game;
  }
}
