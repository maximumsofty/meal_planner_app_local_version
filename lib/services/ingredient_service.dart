// lib/services/ingredient_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ingredient.dart';
import '../data/default_ingredients.dart';

/// Service for loading and saving Ingredient data locally.
class IngredientService {
  static const _storageKey = 'ingredients';

  /// Loads the list of saved Ingredients.
  /// Seeds with [defaultIngredients] if nothing saved **or** the saved list is empty.
  Future<List<Ingredient>> loadIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    // Nothing stored yet ➜ seed defaults
    if (jsonString == null || jsonString.isEmpty) {
      await saveIngredients(defaultIngredients);
      // Return a copy so callers can modify without touching the constant source
      return List<Ingredient>.from(defaultIngredients);
    }

    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      if (decoded.isEmpty) {
        // Stored list is empty ➜ reseed
        await saveIngredients(defaultIngredients);
        return List<Ingredient>.from(defaultIngredients);
      }
      return decoded
          .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt JSON ➜ reseed
      await saveIngredients(defaultIngredients);
      return List<Ingredient>.from(defaultIngredients);
    }
  }

  /// Saves the given list of Ingredients.
  Future<void> saveIngredients(List<Ingredient> ingredients) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(ingredients.map((i) => i.toJson()).toList());
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

  /// Convenience helper if you ever want to wipe user data and
  /// restore the factory defaults (e.g. for a “Reset” button).
  Future<void> resetToDefaults() async => saveIngredients(defaultIngredients);
}
