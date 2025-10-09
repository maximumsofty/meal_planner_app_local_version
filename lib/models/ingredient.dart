// lib/models/ingredient.dart

import 'dart:convert';

/// Represents a single ingredient with its default weight and full nutritional details.
class Ingredient {
  final String id;
  String name;
  double defaultWeight; // grams
  double calories;
  double carbs; // grams
  double fat; // grams
  double protein; // grams

  Ingredient({
    required this.id,
    required this.name,
    required this.defaultWeight,
    required this.calories,
    required this.carbs,
    required this.fat,
    required this.protein,
  });

  /// Create a copy with updated fields.
  Ingredient copyWith({
    String? id,
    String? name,
    double? defaultWeight,
    double? calories,
    double? carbs,
    double? fat,
    double? protein,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultWeight: defaultWeight ?? this.defaultWeight,
      calories: calories ?? this.calories,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      protein: protein ?? this.protein,
    );
  }

  /// Convert an Ingredient into a Map for JSON storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'defaultWeight': defaultWeight,
      'calories': calories,
      'carbs': carbs,
      'fat': fat,
      'protein': protein,
    };
  }

  /// Construct an Ingredient from a JSON Map.
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String,
      name: json['name'] as String,
      defaultWeight: (json['defaultWeight'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
    );
  }

  /// Helper to encode to a JSON string.
  String encode() => jsonEncode(toJson());

  /// Helper to decode from a JSON string.
  static Ingredient decode(String jsonString) =>
      Ingredient.fromJson(jsonDecode(jsonString));
}
