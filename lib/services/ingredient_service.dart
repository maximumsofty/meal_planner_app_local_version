// lib/services/ingredient_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ingredient.dart';

/// Service for loading and saving Ingredient data locally.
class IngredientService {
  static const _storageKey = 'ingredients';

  /// Loads the list of saved Ingredients.
  Future<List<Ingredient>> loadIngredients() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonString);
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
}
