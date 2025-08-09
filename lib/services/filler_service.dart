// lib/services/filler_service.dart
//
// Stores a single global filler ingredient ID for each macro
// using SharedPreferences.
//
// keys: 'carb', 'protein', 'fat'  ➜  ingredientId

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FillerService {
  static const _storageKey = 'macro_fillers';

  Future<Map<String, String>> _loadRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_storageKey);
    if (str == null) return {};
    return (jsonDecode(str) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as String));
  }

  Future<void> _saveRaw(Map<String, String> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  Future<String?> getFillerId(String macroKey) async {
    final map = await _loadRaw();
    return map[macroKey];
  }

  Future<void> setFillerId(String macroKey, String ingredientId) async {
    final map = await _loadRaw();
    map[macroKey] = ingredientId;
    await _saveRaw(map);
  }
}
