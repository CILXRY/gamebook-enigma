import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_entry.dart';

class StorageService {
  static const _key = 'game_entries';

  static Future<List<GameEntry>> loadGames() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => GameEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveGames(List<GameEntry> games) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(games.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }
}
