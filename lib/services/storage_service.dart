import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_entry.dart';
import '../models/sentence_template.dart';
import '../constants/preset_defaults.dart';

class StorageService {
  static const _gameKey = 'game_entries';
  static const _templatesKey = 'sentence_templates';
  static const _presetTagsKey = 'preset_tags';

  static Future<List<GameEntry>> loadGames() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_gameKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => GameEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveGames(List<GameEntry> games) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(games.map((e) => e.toJson()).toList());
    await prefs.setString(_gameKey, jsonString);
  }

  static Future<List<SentenceTemplate>> loadSentenceTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_templatesKey);
    if (raw == null || raw.isEmpty) {
      return List.from(defaultSentenceTemplates);
    }
    final List<dynamic> list = json.decode(raw);
    return list.map((e) => SentenceTemplate.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveSentenceTemplates(List<SentenceTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(templates.map((e) => e.toJson()).toList());
    await prefs.setString(_templatesKey, jsonString);
  }

  static Future<List<String>> loadPresetTags() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_presetTagsKey);
    if (raw == null || raw.isEmpty) {
      return List.from(defaultPresetTags);
    }
    final List<dynamic> list = json.decode(raw);
    return list.cast<String>();
  }

  static Future<void> savePresetTags(List<String> tags) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(tags);
    await prefs.setString(_presetTagsKey, jsonString);
  }

  static Future<void> resetSentenceTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_templatesKey);
  }

  static Future<void> resetPresetTags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_presetTagsKey);
  }
}
