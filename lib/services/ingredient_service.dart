// lib/services/ingredient_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ingredient.dart';
import '../data/default_ingredients.dart';

/// Service for loading and saving Ingredient data locally.
class IngredientService {
  static const _storageKey = 'ingredients';

  /// Loads the list of saved Ingredients.
  /// If none exist, seeds from [defaultIngredients] and returns them.
  Future<List<Ingredient>> loadIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null) {
      // First run (or storage cleared): seed defaults
      await saveIngredients(defaultIngredients);
      return defaultIngredients;
    }

    final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded
        .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Saves the given list of Ingredients.
  Future<void> saveIngredients(List<Ingredient> ingredients) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = ingredients.map((i) => i.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_storageKey, jsonString);
  }

  /// Adds or updates an Ingredient in the saved list.
  Future<void> upsertIngredient(Ingredient ingredient) async {
    final list = await loadIngredients();
    final index = list.indexWhere((i) => i.id == ingredient.id);
    if (index >= 0) {
      list[index] = ingredient;
    } else {
      list.add(ingredient);
    }
    await saveIngredients(list);
  }

  /// Deletes an Ingredient by its id.
  Future<void> deleteIngredient(String id) async {
    final list = await loadIngredients();
    list.removeWhere((i) => i.id == id);
    await saveIngredients(list);
  }

  /// Overwrite saved ingredients with the built-in defaults.
  Future<void> resetToDefaults() async {
    await saveIngredients(defaultIngredients);
  }

  /// TEMP/utility: remove the storage key entirely.
  /// Next call to [loadIngredients] will re-seed defaults.
  Future<void> clearAllIngredientsStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}