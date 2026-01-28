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
  final String? fillerCarbId; // autofill ingredient IDs
  final String? fillerProteinId;
  final String? fillerFatId;

  Meal({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.favorite,
    required this.mealTypeId,
    required this.rows,
    this.fillerCarbId,
    this.fillerProteinId,
    this.fillerFatId,
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
    fillerCarbId: j['fillerCarbId'] as String?,
    fillerProteinId: j['fillerProteinId'] as String?,
    fillerFatId: j['fillerFatId'] as String?,
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
    if (fillerCarbId != null) 'fillerCarbId': fillerCarbId,
    if (fillerProteinId != null) 'fillerProteinId': fillerProteinId,
    if (fillerFatId != null) 'fillerFatId': fillerFatId,
  };
}
