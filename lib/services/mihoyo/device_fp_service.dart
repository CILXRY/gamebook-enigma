import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'device_id.dart';
import 'device_info_provider.dart';
import 'mihoyo_api_client.dart';

class DeviceFpService {
  static const _fpKey = 'device_fp';
  static const _seedKey = 'seed_id';

  final MihoyoApiClient _client;

  DeviceFpService({MihoyoApiClient? client})
    : _client = client ?? MihoyoApiClient();

  static Future<String?> loadDeviceFp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fpKey);
  }

  static Future<String?> loadSeedId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_seedKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fpKey);
    await prefs.remove(_seedKey);
  }

  static String generateId() {
    final uuid = _uuid4().replaceAll('-', '');
    return uuid.substring(0, 13);
  }

  Future<Map<String, dynamic>> getOrFetch() async {
    final existing = await loadDeviceFp();
    if (existing != null && existing.isNotEmpty) {
      final seedId = await loadSeedId();
      return {'device_fp': existing, 'seed_id': seedId ?? ''};
    }
    return _fetchNew();
  }

  Future<Map<String, dynamic>> regenerate() async {
    await clear();
    return _fetchNew();
  }

  Future<Map<String, dynamic>> _fetchNew() async {
    final deviceIdRaw = await DeviceIdService.getOrCreate();
    final deviceId = deviceIdRaw.replaceAll('-', '');

    final seedId = generateId();
    final initialFp = generateId();

    final platform = Platform.isIOS ? '1' : '2';
    final seedTime = DateTime.now().millisecondsSinceEpoch.toString();

    final override = await DeviceInfoProvider.loadOverride();
    String extFieldsStr;
    if (override != null && override.isNotEmpty) {
      extFieldsStr = override;
    } else {
      final extFieldsMap = await DeviceInfoProvider.collect();
      extFieldsStr = _jsonEncodeSorted(extFieldsMap);
    }

    final body = <String, dynamic>{
      'seed_id': seedId,
      'device_id': deviceId,
      'platform': platform,
      'seed_time': seedTime,
      'app_name': 'bbs_cn',
      'device_fp': initialFp,
      'ext_fields': extFieldsStr,
    };

    final response = await _client.post(
      Uri.parse('https://public-data-api.mihoyo.com/device-fp/api/getFp'),
      body: body,
    );

    final retCode = response['retcode'] as int? ?? -1;
    if (retCode != 0) {
      final message = response['message'] as String? ?? '未知错误';
      throw MihoyoApiException(retCode, message);
    }

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw MihoyoApiException(-1, '响应中缺少 data 字段');
    }

    final deviceFpRaw = data['device_fp'];
    if (deviceFpRaw == null || deviceFpRaw.toString().isEmpty) {
      throw MihoyoApiException(-1, '响应中缺少 device_fp 字段');
    }

    final deviceFp = deviceFpRaw.toString();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fpKey, deviceFp);
    await prefs.setString(_seedKey, seedId);

    return {'device_fp': deviceFp, 'seed_id': seedId};
  }

  String _jsonEncodeSorted(Map<String, dynamic> map) {
    final sortedKeys = map.keys.toList()..sort();
    final sorted = <String, dynamic>{};
    for (final key in sortedKeys) {
      sorted[key] = map[key];
    }
    return json.encode(sorted);
  }

  static String _uuid4() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    return '${_hex(b.sublist(0, 4))}-'
        '${_hex(b.sublist(4, 6))}-'
        '${_hex(b.sublist(6, 8))}-'
        '${_hex(b.sublist(8, 10))}-'
        '${_hex(b.sublist(10, 16))}';
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
