import 'package:shared_preferences/shared_preferences.dart';

class EndpointService {
  static const _defaults = {
    'hkrpg_cn':
        'https://api-takumi-record.mihoyo.com/game_record/app/hkrpg/api/index?server=prod_gf_cn&role_id={UID}',
    'hk4e_cn': '',
    'nap_cn': '',
  };

  static const _prefix = 'endpoint_';

  static Future<Map<String, String>> loadAll() async {
    final prefs = await _prefs;
    final result = <String, String>{};
    for (final biz in _defaults.keys) {
      result[biz] = prefs.getString('$_prefix$biz') ?? _defaults[biz]!;
    }
    return result;
  }

  static Future<String?> load(String gameBiz) async {
    final prefs = await _prefs;
    return prefs.getString('$_prefix$gameBiz') ?? _defaults[gameBiz];
  }

  static Future<void> save(String gameBiz, String url) async {
    final prefs = await _prefs;
    await prefs.setString('$_prefix$gameBiz', url);
  }

  static Future<void> resetDefault(String gameBiz) async {
    final prefs = await _prefs;
    await prefs.remove('$_prefix$gameBiz');
  }

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();
}
