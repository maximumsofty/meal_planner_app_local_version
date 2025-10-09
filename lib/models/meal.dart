// lib/models/meal.dart
import 'ingredient.dart';
import 'meal_ingredient.dart';

class Meal {
  final String id;
  final String name;
  final DateTime createdAt;
  final bool favorite;
  final String mealTypeId; // link to MealType
  final List<MealIngredient> rows; // fillers + main rows in order

  Meal({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.favorite,
    required this.mealTypeId,
    required this.rows,
  });

  factory Meal.fromJson(Map<String, dynamic> j) => Meal(
    id: j['id'],
    name: j['name'],
    createdAt: DateTime.parse(j['createdAt']),
    favorite: j['favorite'] as bool,
    mealTypeId: j['mealTypeId'],
    rows: (j['rows'] as List)
        .map(
          (e) => MealIngredient(
            ingredient: Ingredient.fromJson(e['ingredient']),
            weight: (e['weight'] as num).toDouble(),
          )..locked = e['locked'] as bool,
        )
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'favorite': favorite,
    'mealTypeId': mealTypeId,
    'rows': rows
        .map(
          (mi) => {
            'ingredient': mi.ingredient.toJson(),
            'weight': mi.weight,
            'locked': mi.locked,
          },
        )
        .toList(),
  };
}
