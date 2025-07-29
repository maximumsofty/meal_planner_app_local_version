// lib/services/meal_type_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_type.dart';

/// Service for loading and saving MealType data locally.
class MealTypeService {
  static const _storageKey = 'meal_types';

  /// Loads the list of saved MealTypes.
  Future<List<MealType>> loadMealTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded
        .map((e) => MealType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Saves the given list of MealTypes.
  Future<void> saveMealTypes(List<MealType> mealTypes) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = mealTypes.map((mt) => mt.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_storageKey, jsonString);
  }

  /// Adds or updates a MealType in the saved list.
  Future<void> upsertMealType(MealType mealType) async {
    final list = await loadMealTypes();
    final index = list.indexWhere((mt) => mt.id == mealType.id);
    if (index >= 0) {
      list[index] = mealType;
    } else {
      list.add(mealType);
    }
    await saveMealTypes(list);
  }

  /// Deletes a MealType by its id.
  Future<void> deleteMealType(String id) async {
    final list = await loadMealTypes();
    list.removeWhere((mt) => mt.id == id);
    await saveMealTypes(list);
  }
}
