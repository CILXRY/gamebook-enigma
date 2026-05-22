import 'package:flutter/services.dart';
import '../models/app_usage_stats.dart';

class UsageStatsService {
  static const _channel = MethodChannel('gamebook/usage_stats');

  static Future<List<AppUsageStats>> getAllUsageStats() async {
    try {
      final result = await _channel.invokeMethod('getAllUsageStats');
      final list = (result as List<dynamic>?) ?? [];
      return list
          .map((e) => AppUsageStats.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<AppUsageStats>> getUsageStatsForPackage(String packageName) async {
    try {
      final result = await _channel.invokeMethod(
        'getUsageStatsForPackage',
        {'packageName': packageName},
      );
      final list = (result as List<dynamic>?) ?? [];
      return list
          .map((e) => AppUsageStats.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
