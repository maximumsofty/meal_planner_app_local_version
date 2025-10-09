// lib/models/meal_ingredient.dart
import 'ingredient.dart';

/// A wrapper that links an Ingredient with the chosen weight for this meal.
/// It also tracks whether the user has “locked” it.
class MealIngredient {
  final Ingredient ingredient;
  double weight; // grams
  bool locked = false; // NEW

  MealIngredient({required this.ingredient, required this.weight});

  // --- macros re-scaled by weight ---------------------------------------
  double get calories =>
      ingredient.calories * weight / ingredient.defaultWeight;
  double get carbs => ingredient.carbs * weight / ingredient.defaultWeight;
  double get protein => ingredient.protein * weight / ingredient.defaultWeight;
  double get fat => ingredient.fat * weight / ingredient.defaultWeight;
}
