// lib/models/meal_type.dart

import 'dart:convert';

/// Represents a meal category (breakfast, lunch, etc.)
/// with default macro targets.
class MealType {
  final String id;
  String name;
  int calories;
  int carbs;   // in grams
  int protein; // in grams
  int fat;     // in grams

  MealType({
    required this.id,
    required this.name,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  /// Create a copy with updated fields.
  MealType copyWith({
    String? id,
    String? name,
    int? calories,
    int? carbs,
    int? protein,
    int? fat,
  }) {
    return MealType(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
    );
  }

  /// Convert a MealType into a Map for JSON storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
    };
  }

  /// Construct a MealType from a JSON Map.
  factory MealType.fromJson(Map<String, dynamic> json) {
    return MealType(
      id: json['id'] as String,
      name: json['name'] as String,
      calories: json['calories'] as int,
      carbs: json['carbs'] as int,
      protein: json['protein'] as int,
      fat: json['fat'] as int,
    );
  }

  /// Helper to encode to a JSON string.
  String encode() => jsonEncode(toJson());

  /// Helper to decode from a JSON string.
  static MealType decode(String jsonString) =>
      MealType.fromJson(jsonDecode(jsonString));
}
