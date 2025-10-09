// lib/services/meal_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal.dart';

class MealService {
  static const _key = 'meals';

  Future<List<Meal>> loadMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_key);
    if (str == null) return [];
    final list = (jsonDecode(str) as List)
        .map((e) => Meal.fromJson(e as Map<String, dynamic>))
        .toList();
    // newest first
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveMeals(List<Meal> meals) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(meals.map((m) => m.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }

  Future<void> addMeal(Meal meal) async {
    final list = await loadMeals();
    list.add(meal);
    await saveMeals(list);
  }

  Future<void> upsertMeal(Meal meal) async {
    final list = await loadMeals();
    final idx = list.indexWhere((m) => m.id == meal.id);
    if (idx >= 0) {
      list[idx] = meal;
    } else {
      list.add(meal);
    }
    await saveMeals(list);
  }

  Future<void> toggleFavorite(String mealId) async {
    final list = await loadMeals();
    final idx = list.indexWhere((m) => m.id == mealId);
    if (idx >= 0) {
      list[idx] = Meal(
        id: list[idx].id,
        name: list[idx].name,
        createdAt: list[idx].createdAt,
        favorite: !list[idx].favorite,
        mealTypeId: list[idx].mealTypeId,
        rows: list[idx].rows,
      );
      await saveMeals(list);
    }
  }

  Future<void> deleteMeal(String mealId) async {
    final list = await loadMeals();
    list.removeWhere((m) => m.id == mealId);
    await saveMeals(list);
  }
}
