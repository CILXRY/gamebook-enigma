import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdService {
  static const _key = 'x_rpc_device_id';

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_key);
    if (id != null && id.isNotEmpty) return id;

    final newId = _uuid4();
    await prefs.setString(_key, newId);
    return newId;
  }

  static Future<String> regenerate() async {
    final prefs = await SharedPreferences.getInstance();
    final newId = _uuid4();
    await prefs.setString(_key, newId);
    return newId;
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
