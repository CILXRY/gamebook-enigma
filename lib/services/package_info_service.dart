import 'dart:io';
import 'package:flutter/services.dart';
import '../models/android_package_model.dart';

class PackageInfoService {
  static const _channel = MethodChannel('gamebook/packages');

  static final Map<String, String> _iconCache = {};

  static Future<List<AndroidPackageModel>> getInstalledPackages() async {
    try {
      final result = await _channel.invokeMethod('getInstalledPackages');
      final list = (result as List<dynamic>?) ?? [];
      return list
          .map((e) => AndroidPackageModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<String> getAppIcon(String packageName) async {
    if (_iconCache.containsKey(packageName)) {
      return _iconCache[packageName]!;
    }
    try {
      final result = await _channel.invokeMethod('getAppIcon', {'packageName': packageName});
      final icon = (result as String?) ?? '';
      if (icon.isNotEmpty) {
        _iconCache[packageName] = icon;
      }
      return icon;
    } catch (e) {
      return '';
    }
  }

  static Future<Map<String, int>?> getPackageStorageSize(String packageName) async {
    if (!Platform.isAndroid) return null;
    try {
      final result = await _channel.invokeMethod('getPackageStorageSize', {'packageName': packageName});
      if (result == null) return null;
      final map = Map<String, dynamic>.from(result as Map);
      return {
        'appBytes': (map['appBytes'] as num?)?.toInt() ?? 0,
        'dataBytes': (map['dataBytes'] as num?)?.toInt() ?? 0,
        'cacheBytes': (map['cacheBytes'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isUsagePermissionGranted() async {
    try {
      final result = await _channel.invokeMethod('isUsagePermissionGranted');
      return (result as bool?) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> openUsageSettings() async {
    try {
      await _channel.invokeMethod('openUsageSettings');
    } catch (_) {}
  }

  static Future<String> getPackageVersion(String packageName) async {
    try {
      final result = await _channel.invokeMethod('getPackageVersion', {'packageName': packageName});
      return (result as String?) ?? '';
    } catch (e) {
      return '';
    }
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
